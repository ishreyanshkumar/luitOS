#!/usr/bin/env python3
"""Timing-stable public functional test for CS3106L Lab 4.

The harness never sleeps for an assumed boot duration.  It waits for the real
Luit shell prompt, starts lazytest, and then waits for lazytest's own PASS/FAIL
marker.  Timeouts are safety ceilings only.
"""

import os
import shutil
import tempfile

from qemu_harness import BOOT_TIMEOUT, QemuSession

PANIC_MARKERS = ["panic", "PANIC", "Oops"]
REQUIRED = [
    "LAB4: PASS",
    "[PASS] sbrk reserves virtual memory without eager data pages",
    "[PASS] first user load/store materializes zero-filled pages",
    "[PASS] sparse heap touches allocate only on demand",
    "[PASS] address at or beyond the process break is rejected",
    "[PASS] stack guard page remains protected",
    "[PASS] kernel copyout materializes a cross-page lazy destination",
    "[PASS] kernel copyin reads an untouched lazy page as zeros",
    "[PASS] kernel copyinstr can read a valid untouched lazy page",
    "[PASS] shrinking frees mapped pages and tolerates lazy holes",
    "[PASS] shrink then regrow returns fresh zero-filled memory",
    "[PASS] fork preserves lazy holes and process isolation",
]


def run_one(cpus):
    fd, img = tempfile.mkstemp(prefix=f".fs.lab04.{cpus}.", suffix=".img", dir=".")
    os.close(fd)
    shutil.copyfile("fs.img", img)
    note = None

    try:
        with QemuSession(cpus, "128M", image=img) as q:
            if not q.wait_for_prompt(timeout=BOOT_TIMEOUT):
                note = "guest shell prompt did not appear before the safety timeout"
            else:
                start = q.position()
                q.send_line("lazytest")
                marker = q.wait_for_any(
                    ["LAB4: PASS", "LAB4: FAIL", "panic", "PANIC"],
                    timeout=180,
                    start=start,
                )
                if marker is None:
                    note = "lazytest did not finish before the safety timeout"
            tr = q.text()
    finally:
        try:
            os.unlink(img)
        except FileNotFoundError:
            pass

    missing = [m for m in REQUIRED if m not in tr]
    bad = [m for m in PANIC_MARKERS if m in tr]
    ok = note is None and not missing and not bad

    if ok:
        print(f"[PASS] lab04 lazy memory CPUS={cpus}")
        return True

    print(f"[FAIL] lab04 lazy memory CPUS={cpus}")
    if note:
        print(f"       harness: {note}")
    for m in missing:
        print(f"       missing: {m!r}")
    for m in bad:
        print(f"       forbidden marker present: {m!r}")
    print("       --- last 100 lines of transcript ---")
    for line in tr.splitlines()[-100:]:
        print("       | " + line)
    return False


def main():
    ok1 = run_one(1)
    ok4 = run_one(4) if ok1 else False
    return 0 if ok1 and ok4 else 1


if __name__ == "__main__":
    raise SystemExit(main())
