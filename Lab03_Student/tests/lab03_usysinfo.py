#!/usr/bin/env python3
"""Timing-stable Lab 3 public functional test.

No fixed boot sleeps are used.  The driver waits for the real Luit shell prompt
before starting usitest, then waits for the test's own PASS/FAIL marker.
"""

import os
import shutil
import tempfile

from qemu_harness import BOOT_TIMEOUT, QemuSession

PANIC_MARKERS = ["panic", "PANIC", "Oops"]
REQUIRED = [
    "LAB3: PASS",
    "[PASS] consistent multi-field snapshots",
    "[PASS] fast getpid executes no syscall",
    "[PASS] fast uptime executes no syscall",
    "[PASS] read-only mapping",
    "[PASS] exec remaps info page",
]


def run_one(cpus):
    fd, img = tempfile.mkstemp(prefix=f".fs.lab03.{cpus}.", suffix=".img", dir=".")
    os.close(fd)
    shutil.copyfile("fs.img", img)
    note = None

    try:
        with QemuSession(cpus, "128M", image=img) as q:
            if not q.wait_for_prompt(timeout=BOOT_TIMEOUT):
                note = "guest shell prompt did not appear before the safety timeout"
            else:
                start = q.position()
                q.send_line("usitest")
                marker = q.wait_for_any(["LAB3: PASS", "LAB3: FAIL", "panic", "PANIC"],
                                        timeout=150, start=start)
                if marker is None:
                    note = "usitest did not finish before the safety timeout"
            tr = q.text()
    finally:
        try:
            os.unlink(img)
        except FileNotFoundError:
            pass

    missing = [m for m in REQUIRED if m not in tr]
    ok = note is None and not missing and not any(m in tr for m in PANIC_MARKERS)
    if ok:
        print(f"[PASS] lab03 usysinfo CPUS={cpus}")
        return True

    print(f"[FAIL] lab03 usysinfo CPUS={cpus}")
    if note:
        print(f"       harness: {note}")
    for m in missing:
        print(f"       missing: {m!r}")
    print("       --- last 80 lines of transcript ---")
    for line in tr.splitlines()[-80:]:
        print("       | " + line)
    return False


def main():
    ok1 = run_one(1)
    ok4 = run_one(4) if ok1 else False
    return 0 if ok1 and ok4 else 1


if __name__ == "__main__":
    raise SystemExit(main())
