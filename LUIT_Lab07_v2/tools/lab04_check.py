#!/usr/bin/env python3
"""Local submission-structure check for CS3106L Lab 4.

The official grader extracts K1-K4 from a clean checkpoint.  This script checks
that the same four marked regions are still present and uniquely extractable.
It intentionally does not judge correctness; `make grade LAB=4` does that.
"""

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
REGIONS = {
    "kernel/proc.c": ("K1",),
    "kernel/vm.c": ("K2", "K4"),
    "kernel/trap.c": ("K3",),
}
REQUIRED_FILES = [
    "kernel/defs.h",
    "kernel/exec.c",
    "user/lazytest.c",
    "tests/lab04_lazy.py",
    "tests/qemu_harness.py",
]


def pattern(tag):
    return re.compile(
        r"(?ms)(/\*\s*TODO-BEGIN\s+" + re.escape(tag)
        + r"\b.*?\*/)(.*?)(/\*\s*TODO-END\s+" + re.escape(tag) + r"\s*\*/)"
    )


def fail(msg):
    print("LAB04 CHECK: FAIL")
    print("  " + msg)
    return 1


def main():
    for rel in REQUIRED_FILES:
        if not (ROOT / rel).is_file():
            return fail(f"missing required checkpoint file: {rel}")

    for rel, tags in REGIONS.items():
        p = ROOT / rel
        if not p.is_file():
            return fail(f"missing required file: {rel}")
        text = p.read_text(errors="replace")
        for tag in tags:
            matches = list(pattern(tag).finditer(text))
            if len(matches) != 1:
                return fail(
                    f"{rel}: TODO region {tag} is missing, duplicated, or its markers were changed"
                )

    print("LAB04 CHECK: PASS")
    print("  K1/K2/K3/K4 are present and can be extracted by the official grader.")
    print("  This check verifies submission structure, not functional correctness.")
    print("  Next run: make clean && make && make grade LAB=4")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
