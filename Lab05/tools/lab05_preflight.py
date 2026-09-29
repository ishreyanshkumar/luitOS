#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path.cwd()

REQUIRED = [
    "Makefile",
    "kernel/spinlock.c",
    "kernel/proc.c",
    "kernel/syscall.tbl",
    "user/ulib.h",
]
REQUIRED_CALLS = {"fork", "exit", "wait", "pipe", "read", "write", "close", "sleep"}


def fail(msg: str) -> None:
    print(f"[FAIL] {msg}")


def ok(msg: str) -> None:
    print(f"[PASS] {msg}")


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8", errors="replace")


def kernel_c_files() -> list[Path]:
    return sorted((ROOT / "kernel").glob("*.c"))


def find_token(token: str) -> list[str]:
    hits = []
    rx = re.compile(rf"\b{re.escape(token)}\b")
    for path in kernel_c_files():
        text = path.read_text(encoding="utf-8", errors="replace")
        if rx.search(text):
            hits.append(str(path.relative_to(ROOT)))
    return hits


def main() -> int:
    errors = 0
    print("=== CS3106L Lab 5 preflight ===")

    for path in REQUIRED:
        if (ROOT / path).is_file():
            ok(path)
        else:
            fail(f"missing {path}")
            errors += 1

    if errors:
        print("LAB5 preflight: FAIL")
        return 1

    mk = read("Makefile")
    if "UPROGS" in mk:
        ok("Makefile contains UPROGS")
    else:
        fail("could not find UPROGS in Makefile")
        errors += 1

    syscalls = read("kernel/syscall.tbl")
    names = set()
    for line in syscalls.splitlines():
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        fields = line.split()
        if len(fields) >= 2 and fields[0].isdigit():
            names.add(fields[1])
    missing = sorted(REQUIRED_CALLS - names)
    if not missing:
        ok("required existing system calls are present")
    else:
        fail("missing system calls: " + ", ".join(missing))
        errors += 1

    spin = read("kernel/spinlock.c")
    for token in ("push_off", "pop_off", "__sync_lock_test_and_set", "__sync_lock_release"):
        if token in spin:
            ok(f"spinlock path contains {token}")
        else:
            fail(f"kernel/spinlock.c does not contain {token}")
            errors += 1

    sleep_hits = find_token("sleep")
    wake_hits = find_token("wakeup")
    pipewrite_hits = find_token("pipewrite")
    piperead_hits = find_token("piperead")

    if sleep_hits:
        ok("sleep found in: " + ", ".join(sleep_hits))
    else:
        fail("could not find kernel sleep implementation/use")
        errors += 1

    if wake_hits:
        ok("wakeup found in: " + ", ".join(wake_hits))
    else:
        fail("could not find kernel wakeup implementation/use")
        errors += 1

    if pipewrite_hits and piperead_hits:
        ok("pipewrite/piperead found in kernel source")
        print("       pipewrite: " + ", ".join(pipewrite_hits))
        print("       piperead : " + ", ".join(piperead_hits))
    else:
        fail("could not find both pipewrite and piperead")
        errors += 1

    # Find a visible pipe-capacity constant when one exists.  This is advisory;
    # the experiment still works as a correctness test if the name differs.
    capacity = None
    cap_path = None
    cap_rx = re.compile(r"#\s*define\s+(?:PIPE(?:SIZE|_SIZE)|PIPESIZE)\s+(\d+)")
    for path in kernel_c_files() + sorted((ROOT / "kernel").glob("*.h")):
        text = path.read_text(encoding="utf-8", errors="replace")
        m = cap_rx.search(text)
        if m:
            capacity = int(m.group(1))
            cap_path = str(path.relative_to(ROOT))
            break

    planned = 4 * 2048
    if capacity is not None:
        ok(f"pipe capacity constant appears to be {capacity} bytes in {cap_path}")
        if planned > capacity:
            ok(f"planned {planned} one-byte writes exceed that capacity")
        else:
            print(f"[WARN] planned traffic ({planned}) does not exceed detected capacity ({capacity})")
            print("       increase NWRITES in user/pipe_stress.c before the blocking observation")
    else:
        print("[INFO] pipe capacity constant name was not detected automatically")
        print("       inspect the pipe implementation before the blocking observation")

    if errors:
        print(f"LAB5 preflight: FAIL ({errors} problem(s))")
        return 1

    print("LAB5 preflight: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
