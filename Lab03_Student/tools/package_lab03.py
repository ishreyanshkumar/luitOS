#!/usr/bin/env python3
"""Create the exact Lab 3 submission ZIP.

The ZIP contains only kernel/usysinfo.c and user/ulib.c under one roll-numbered
folder. It is reopened after creation and its member list is checked exactly.
"""
from pathlib import Path
import re, subprocess, sys, zipfile

ROOT = Path(__file__).resolve().parents[1]
FILES = ["kernel/usysinfo.c", "user/ulib.c"]

def main():
    if len(sys.argv) != 2 or not re.fullmatch(r"[A-Za-z0-9_-]{5,24}", sys.argv[1]):
        print("usage: python3 tools/package_lab03.py YOUR_ROLL_NUMBER", file=sys.stderr)
        return 2
    roll = sys.argv[1]

    check = subprocess.run([sys.executable, str(ROOT / "tools/lab03_check.py")], cwd=ROOT)
    if check.returncode:
        return check.returncode

    top = f"{roll}_Lab03"
    out = ROOT / f"{top}.zip"
    if out.exists():
        out.unlink()

    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for rel in FILES:
            p = ROOT / rel
            if not p.is_file():
                print(f"missing required file: {rel}", file=sys.stderr)
                return 1
            z.write(p, f"{top}/{rel}")

    expected = [f"{top}/{rel}" for rel in FILES]
    try:
        with zipfile.ZipFile(out, "r") as z:
            names = z.namelist()
            bad = z.testzip()
    except zipfile.BadZipFile:
        print("submission ZIP verification failed: invalid ZIP", file=sys.stderr)
        return 1

    if len(names) != len(expected) or set(names) != set(expected) or bad is not None:
        print("submission ZIP verification failed", file=sys.stderr)
        print("expected exactly:", file=sys.stderr)
        for n in expected:
            print("  " + n, file=sys.stderr)
        print("found:", file=sys.stderr)
        for n in names:
            print("  " + n, file=sys.stderr)
        if bad:
            print(f"corrupt member: {bad}", file=sys.stderr)
        out.unlink(missing_ok=True)
        return 1

    print(f"Created: {out.name}")
    print("Verified ZIP contents:")
    for n in expected:
        print("  " + n)
    print("Upload this ZIP. Do not add any other files.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
