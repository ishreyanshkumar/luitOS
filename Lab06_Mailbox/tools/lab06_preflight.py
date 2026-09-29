#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

REQUIRED = [
    "Makefile",
    "kernel/main.c",
    "kernel/defs.h",
    "kernel/proc.c",
    "kernel/spinlock.c",
    "kernel/syscall.tbl",
    "tools/gensyscalls.py",
    "user/ulib.h",
]
REQUIRED_CALLS = {"fork", "exit", "wait", "pipe", "read", "write", "close", "sleep"}
NEW_CALLS = {"mbox_send", "mbox_recv", "mbox_close"}


def read(root: Path, rel: str) -> str:
    return (root / rel).read_text(encoding="utf-8", errors="replace")


def ok(msg: str) -> None:
    print(f"[PASS] {msg}")


def fail(msg: str) -> None:
    print(f"[FAIL] {msg}")


def parse_syscalls(text: str):
    rows = []
    errors = []
    for lineno, raw in enumerate(text.splitlines(), 1):
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        fields = line.split()
        if len(fields) < 3 or not fields[0].isdigit():
            errors.append(f"line {lineno}: expected 'number name handler'")
            continue
        rows.append((int(fields[0]), fields[1], fields[2]))
    return rows, errors


def find_kernel_build_mode(mk: str):
    if re.search(r"wildcard\s+kernel/\*\.c", mk) or re.search(r"kernel/\*\.c", mk):
        return "wildcard", None
    patterns = [
        r"kernel/proc\.o",
        r"\$\(K\)/proc\.o",
        r"\$K/proc\.o",
    ]
    for pat in patterns:
        m = re.search(pat, mk)
        if m:
            return "explicit", m.group(0)
    return None, None


def kernel_has(root: Path, token: str) -> bool:
    rx = re.compile(rf"\b{re.escape(token)}\b")
    for path in (root / "kernel").glob("*.c"):
        if rx.search(path.read_text(encoding="utf-8", errors="replace")):
            return True
    return False


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: python3 tools/lab06_preflight.py /path/to/COMPLETED_LUIT_TREE", file=sys.stderr)
        print("Lab06_Mailbox is an overlay package, not the LUIT source tree.", file=sys.stderr)
        print("Pass the directory where the existing top-level Makefile, kernel/, user/, and tools/ live.", file=sys.stderr)
        return 2

    root = Path(sys.argv[1]).resolve()
    print("=== CS3106L Lab 6 preflight ===")
    print(f"LUIT root: {root}")
    errors = 0

    if not root.is_dir():
        fail(f"not a directory: {root}")
        return 1

    # A common mistake is to pass the extracted Lab 6 package itself.  That
    # directory contains starter/ and this script, but it is not a bootable
    # LUIT checkout and intentionally has no Makefile.
    if (root / "starter/kernel/mailbox.c").is_file() and not (root / "kernel/proc.c").is_file():
        fail("this path is the Lab 6 package, not the completed LUIT tree")
        print("Use the completed Lab 4 LUIT root -- the directory in which `make` already works.")
        return 1

    for rel in REQUIRED:
        if (root / rel).is_file():
            ok(rel)
        else:
            if rel == "Makefile":
                fail("missing top-level Makefile in the target LUIT tree")
                print("       The Lab 6 ZIP intentionally does not ship a Makefile; it patches the one already in the completed LUIT tree.")
            else:
                fail(f"missing {rel}")
            errors += 1
    if errors:
        print("LAB6 preflight: FAIL")
        return 1

    mk = read(root, "Makefile")
    if "UPROGS" in mk and "user/" in mk:
        ok("Makefile has a user-program list")
    else:
        fail("could not recognize UPROGS using user/... paths")
        errors += 1

    mode, token = find_kernel_build_mode(mk)
    if mode == "wildcard":
        ok("Makefile appears to discover kernel C files automatically")
    elif mode == "explicit":
        ok(f"Makefile has an explicit kernel object list ({token})")
    else:
        fail("could not determine how a new kernel/mailbox.c object is linked")
        errors += 1

    mainc = read(root, "kernel/main.c")
    init_hits = re.findall(r"(?m)^\s*(?:pinit|procinit)\(\);\s*$", mainc)
    if len(init_hits) == 1:
        ok("found exactly one process-table initialization call in kernel/main.c")
    else:
        fail(f"expected one pinit()/procinit() call in kernel/main.c; found {len(init_hits)}")
        errors += 1

    defs = read(root, "kernel/defs.h")
    if re.search(r"struct\s+trapframe\s*\{", defs):
        ok("kernel/defs.h contains the LUIT trapframe definition")
    else:
        fail("kernel/defs.h does not contain the expected LUIT trapframe definition")
        errors += 1

    if re.search(r"struct\s+proc\s*\{", defs) and re.search(r"struct\s+trapframe\s*\*\s*tf\b", defs):
        ok("kernel/defs.h exposes struct proc with the LUIT p->tf pointer")
    else:
        fail("kernel/defs.h does not match the expected LUIT struct proc / p->tf layout")
        errors += 1

    rows, parse_errors = parse_syscalls(read(root, "kernel/syscall.tbl"))
    if parse_errors:
        for e in parse_errors:
            fail("kernel/syscall.tbl " + e)
        errors += len(parse_errors)
    else:
        nums = [r[0] for r in rows]
        names = [r[1] for r in rows]
        if len(nums) != len(set(nums)) or len(names) != len(set(names)):
            fail("kernel/syscall.tbl already contains duplicate numbers or names")
            errors += 1
        else:
            ok("kernel/syscall.tbl has unique numbers and names")
        missing = sorted(REQUIRED_CALLS - set(names))
        if missing:
            fail("missing existing calls required by public tests: " + ", ".join(missing))
            errors += 1
        else:
            ok("required existing system calls are present")
        present_new = sorted(NEW_CALLS & set(names))
        if present_new:
            fail("mailbox syscalls already exist: " + ", ".join(present_new))
            errors += 1
        elif nums:
            base = max(nums) + 1
            ok(f"proposed new syscall numbers: {base}, {base+1}, {base+2}")

    spin = read(root, "kernel/spinlock.c")
    for tok in ("push_off", "pop_off", "__sync_lock_test_and_set", "__sync_lock_release"):
        if tok in spin:
            ok(f"kernel/spinlock.c contains {tok}")
        else:
            fail(f"kernel/spinlock.c does not contain {tok}")
            errors += 1

    for tok in ("sleep", "wakeup"):
        if kernel_has(root, tok):
            ok(f"kernel {tok} path found")
        else:
            fail(f"could not find kernel {tok} implementation/use")
            errors += 1

    if errors:
        print(f"LAB6 preflight: FAIL ({errors} issue(s))")
        return 1
    print("LAB6 preflight: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
