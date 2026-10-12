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
            ["make", "qemu", f"CPUS={cpus}"], cwd=ROOT,
            stdin=slave, stdout=slave, stderr=slave,
            close_fds=True, start_new_session=True,
        )
        os.close(slave)
        os.set_blocking(self.master, False)
        self.buf = b""

    def _pump(self, timeout: float) -> None:
        r, _, _ = select.select([self.master], [], [], timeout)
        if r:
            try: data = os.read(self.master, 65536)
            except BlockingIOError: data = b""
            self.buf += data
            if len(self.buf) > 2_000_000:
                self.buf = self.buf[-1_000_000:]

    def wait_for(self, needle: str, timeout: float) -> bool:
        target = needle.encode()
        end = time.time() + timeout
        while time.time() < end:
            if target in self.buf: return True
            if self.proc.poll() is not None: break
            self._pump(min(0.25, max(0.0, end - time.time())))
        return target in self.buf

    def command(self, command: str, marker: str, timeout: float) -> bool:
        self.buf = b""
        os.write(self.master, command.encode() + b"\n")
        end = time.time() + timeout
        if not self.wait_for(marker, timeout):
            print(f"[FAIL] {command} did not produce {marker!r}")
            print(self.buf.decode(errors="replace")[-5000:])
            return False
        if not self.wait_for("luit$", max(0.1, end - time.time())):
            print(f"[FAIL] {command} printed PASS but did not return to the shell")
            print(self.buf.decode(errors="replace")[-5000:])
            return False
        return True

    def close(self) -> None:
        if self.proc.poll() is None:
            try:
                os.write(self.master, b"\x01x")
                self.proc.wait(timeout=5)
            except Exception:
                try: os.killpg(self.proc.pid, signal.SIGTERM)
                except ProcessLookupError: pass
                try: self.proc.wait(timeout=3)
                except Exception:
                    try: os.killpg(self.proc.pid, signal.SIGKILL)
                    except ProcessLookupError: pass
        try: os.close(self.master)
        except OSError: pass


def one_boot(cpus: int, command: str, marker: str, timeout: int) -> bool:
    print(f"\n--- CPUS={cpus}: {command} ---")
    q = QemuSession(cpus)
    try:
        if not q.wait_for("luit$", 45):
            print("[FAIL] shell prompt did not appear")
            print(q.buf.decode(errors="replace")[-5000:])
            return False
        if not q.command(command, marker, timeout):
            return False
        print(f"[PASS] {command}: {marker}")
        return True
    finally:
        q.close()


def main() -> int:
    ap = argparse.ArgumentParser(description="Run Lab 7 public stride-scheduler tests")
    ap.add_argument("--quick", action="store_true", help="skip the separate baseline regression")
    args = ap.parse_args()

    print("=== CS3106L Lab 7 public grade run ===")
    if not run([sys.executable, "tools/lab07_check.py"], 30): return 1
    if not run(["make"], 180):
        print("[FAIL] build"); return 1
    print("[PASS] build")

    if not args.quick:
        if not run([sys.executable, "tests/grade.py"], 300):
            print("[FAIL] baseline regression"); return 1
        print("[PASS] baseline regression")

    tests = [
        (1, "stride_api", "STRIDE_API: PASS", 35),
        (1, "stride_share", "STRIDE_SHARE: PASS", 60),
        (1, "stride_wakeup", "STRIDE_WAKEUP: PASS", 60),
        (4, "stride_smp", "STRIDE_SMP: PASS", 75),
    ]
    for cpus, cmd, marker, timeout in tests:
        if not one_boot(cpus, cmd, marker, timeout): return 1

    # Full mode repeats the schedule-sensitive tests once on fresh boots.
    if not args.quick:
        for cpus, cmd, marker, timeout in tests[1:]:
            if not one_boot(cpus, cmd, marker, timeout): return 1

    print("\nLAB7 PUBLIC: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
