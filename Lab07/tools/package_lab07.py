#!/usr/bin/env python3
from __future__ import annotations

import os
import re
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def die(msg: str) -> None:
    print(f"package_lab07: {msg}", file=sys.stderr)
    raise SystemExit(1)


def main() -> int:
    if len(sys.argv) != 2 or not re.fullmatch(r"[0-9]{9}", sys.argv[1]):
        die("usage: python3 tools/package_lab07.py YOUR_NINE_DIGIT_ROLL")
    roll = sys.argv[1]

    check = subprocess.run([sys.executable, "tools/lab07_check.py"], cwd=ROOT)
    if check.returncode != 0:
        die("release/integrity check failed")

    src = ROOT / "kernel/proc.c"
    if not src.is_file():
        die("kernel/proc.c is missing")

    out = ROOT / f"{roll}_Lab07.zip"
    tmp = ROOT / f".lab07_package_{os.getpid()}.zip"
    arc = f"{roll}_Lab07/kernel/proc.c"

    try:
        with zipfile.ZipFile(tmp, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            zf.write(src, arc)
        with zipfile.ZipFile(tmp, "r") as zf:
            names = zf.namelist()
            if names != [arc] or zf.testzip() is not None:
                die("internal ZIP verification failed")
        os.replace(tmp, out)  # same filesystem: no /tmp cross-device rename
    finally:
        if tmp.exists():
            tmp.unlink()

    print(f"Created {out.name}")
    print(f"Contains exactly: {arc}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
