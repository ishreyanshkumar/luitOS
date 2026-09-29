#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import pty
import select
import signal
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def run(cmd, timeout=180) -> bool:
    print("+", " ".join(cmd))
    try:
        p = subprocess.run(cmd, cwd=ROOT, timeout=timeout)
    except subprocess.TimeoutExpired:
        print(f"[FAIL] timeout: {' '.join(cmd)}")
        return False
    return p.returncode == 0


class QemuSession:
    def __init__(self, cpus: int):
        self.master, slave = pty.openpty()
        self.proc = subprocess.Popen(
            ["make", "qemu", f"CPUS={cpus}"],
            cwd=ROOT,
            stdin=slave,
            stdout=slave,
            stderr=slave,
            close_fds=True,
            start_new_session=True,
        )
        os.close(slave)
        os.set_blocking(self.master, False)
        self.buf = b""

    def _pump(self, timeout: float) -> None:
        r, _, _ = select.select([self.master], [], [], timeout)
        if r:
            try:
                data = os.read(self.master, 65536)
            except BlockingIOError:
                data = b""
            self.buf += data
            if len(self.buf) > 2_000_000:
                self.buf = self.buf[-1_000_000:]

    def wait_for(self, needle: str, timeout: float) -> bool:
        target = needle.encode()
        end = time.time() + timeout
        while time.time() < end:
            if target in self.buf:
                return True
            if self.proc.poll() is not None:
                break
            self._pump(min(0.25, end - time.time()))
        return target in self.buf

    def command(self, command: str, marker: str, timeout: float) -> bool:
        # Discard old output before starting a new command so the marker belongs
        # to this invocation.  Require the shell prompt after the marker as well:
        # seeing a PASS line before the process has actually exited is not enough.
        self.buf = b""
        os.write(self.master, command.encode() + b"\n")
        end = time.time() + timeout
        if not self.wait_for(marker, timeout):
            tail = self.buf.decode(errors="replace")[-4000:]
            print(f"[FAIL] command did not produce {marker!r}: {command}")
            print("--- QEMU output tail ---")
            print(tail)
            print("--- end tail ---")
            return False
        remain = max(0.1, end - time.time())
        if not self.wait_for("luit$", remain):
            tail = self.buf.decode(errors="replace")[-4000:]
            print(f"[FAIL] {command} printed {marker!r} but did not return to the shell")
            print("--- QEMU output tail ---")
            print(tail)
            print("--- end tail ---")
            return False
        return True

    def close(self) -> None:
        if self.proc.poll() is None:
            try:
                os.write(self.master, b"\x01x")  # QEMU: Ctrl-A, x
                self.proc.wait(timeout=5)
            except Exception:
                try:
                    os.killpg(self.proc.pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass
                try:
                    self.proc.wait(timeout=3)
                except Exception:
                    try:
                        os.killpg(self.proc.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
        try:
            os.close(self.master)
        except OSError:
            pass


def qemu_tests(cpus: int, tests):
    print(f"\n--- QEMU public tests: CPUS={cpus} ---")
    q = QemuSession(cpus)
    try:
        if not q.wait_for("luit$", 45):
            print("[FAIL] shell prompt did not appear")
            print(q.buf.decode(errors="replace")[-4000:])
            return False
        for command, marker, timeout in tests:
            if not q.command(command, marker, timeout):
                return False
            print(f"[PASS] {command}: {marker}")
        return True
    finally:
        q.close()


def main() -> int:
    ap = argparse.ArgumentParser(description="Run Lab 6 public tests")
    ap.add_argument("--quick", action="store_true", help="skip the existing baseline make grade suite")
    args = ap.parse_args()

    print("=== CS3106L Lab 6 public grade run ===")
    if not run([sys.executable, "tools/lab06_check.py"], 30):
        return 1
    if not run(["make"], 180):
        print("[FAIL] build")
        return 1
    print("[PASS] build")

    if not args.quick:
        if not run(["make", "grade"], 300):
            print("[FAIL] baseline regression")
            return 1
        print("[PASS] baseline regression")

    # A fresh boot resets every static mailbox.  IDs 0--5 are intentionally
    # disjoint across the two CPUS=1 programs.
    if not qemu_tests(1, [
        ("mbox_basic", "MBOX_BASIC: PASS", 25),
        ("mbox_block", "MBOX_BLOCK: PASS", 45),
    ]):
        return 1

    # Multiple simultaneous waiters are exercised separately on CPUS=4.
    if not qemu_tests(4, [
        ("mbox_multi", "MBOX_MULTI: PASS", 60),
    ]):
        return 1

    # Stress on several harts with several producers and consumers.  The program
    # validates no duplicates and no loss.  The full run repeats the fresh-boot
    # stress test to reduce the chance that a schedule-sensitive bug passes once
    # by luck; --quick performs one stress boot.
    stress_runs = 1 if args.quick else 3
    for run_no in range(1, stress_runs + 1):
        print(f"\n--- stress repetition {run_no}/{stress_runs} ---")
        if not qemu_tests(4, [
            ("mbox_stress", "MBOX_STRESS: PASS", 75),
        ]):
            return 1

    print("\nLAB6 PUBLIC: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
