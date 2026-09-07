#!/usr/bin/env python3
"""Lab 3 local preflight check.

No whole-tree checksum is used. This checker verifies that the four TODO
regions can be extracted in exactly the same way as the official grader.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
REGIONS = {
    "kernel/usysinfo.c": ("K1",),
    "user/ulib.c": ("U1", "U2", "U3"),
}

def pattern(tag):
    return re.compile(
        r"(?ms)(/\*\s*TODO-BEGIN\s+" + re.escape(tag) +
        r"\b.*?\*/)(.*?)(/\*\s*TODO-END\s+" + re.escape(tag) + r"\s*\*/)")

def fail(msg):
    print("LAB03 CHECK: FAIL")
    print("  " + msg)
    return 1

def main():
    for rel, tags in REGIONS.items():
        p = ROOT / rel
        if not p.is_file():
            return fail(f"missing required file: {rel}")
        text = p.read_text(errors="replace")
        for tag in tags:
            matches = list(pattern(tag).finditer(text))
            if len(matches) != 1:
                return fail(f"{rel}: TODO region {tag} is missing, duplicated, or its markers were changed")

    print("LAB03 CHECK: PASS")
    print("  K1/U1/U2/U3 can be extracted by the official grader.")
    print("  No checksum or protected-file hash is used.")
    print("  Next run: make clean && make && make grade LAB=3")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
