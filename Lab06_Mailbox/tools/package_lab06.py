#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "LAB06_RELEASE.json"
SOURCE = ROOT / "kernel/mailbox.c"


def die(msg: str) -> None:
    print(f"package_lab06: ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def validate_roll(roll: str) -> None:
    if not re.fullmatch(r"\d{9}", roll):
        die("roll number must contain exactly nine decimal digits")


def validate_source() -> None:
    if not SOURCE.is_file():
        die("kernel/mailbox.c is missing")
    text = SOURCE.read_text(encoding="utf-8", errors="replace")

    begins = re.findall(r"TODO-BEGIN\s+(M[1-5])\b", text)
    ends = re.findall(r"TODO-END\s+(M[1-5])\b", text)
    expected = ["M1", "M2", "M3", "M4", "M5"]
    if begins != expected or ends != expected:
        die("TODO markers M1--M5 must be preserved exactly once and in order")

    if re.search(r"\bint\s+placeholder\s*;", text) or re.search(r"\.placeholder\b", text):
        die("starter placeholder state is still present in kernel/mailbox.c")

    required = {
        "acquire": r"\bacquire\s*\(",
        "release": r"\brelease\s*\(",
        "sleep": r"\bsleep\s*\(",
        "wakeup": r"\bwakeup\s*\(",
    }
    missing = [name for name, rx in required.items() if not re.search(rx, text)]
    if missing:
        die("implementation does not yet contain required synchronization calls: " + ", ".join(missing))

    try:
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    except Exception as e:
        die(f"cannot read LAB06_RELEASE.json: {e}")
    starter_hash = manifest.get("starter_mailbox_sha256")
    if starter_hash:
        import hashlib
        actual = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
        if actual == starter_hash:
            die("kernel/mailbox.c is still the untouched starter")


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: python3 tools/package_lab06.py NINE_DIGIT_ROLL", file=sys.stderr)
        return 2

    roll = sys.argv[1]
    validate_roll(roll)

    check = subprocess.run([sys.executable, str(ROOT / "tools/lab06_check.py")], cwd=ROOT)
    if check.returncode != 0:
        die("lab06_check.py failed; fix the release/integrity errors before packaging")

    validate_source()

    archive = ROOT / f"{roll}_Lab06.zip"
    top = f"{roll}_Lab06"
    member = f"{top}/kernel/mailbox.c"

    with tempfile.TemporaryDirectory(prefix="lab06-pack-") as td:
        tmp = Path(td) / archive.name
        with zipfile.ZipFile(tmp, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            zf.write(SOURCE, member)

        with zipfile.ZipFile(tmp, "r") as zf:
            names = zf.namelist()
            if names != [member]:
                die(f"internal packaging error: unexpected archive contents {names}")
            if zf.testzip() is not None:
                die("internal packaging error: ZIP integrity test failed")
            packed = zf.read(member)
            if packed != SOURCE.read_bytes():
                die("internal packaging error: archived source differs from kernel/mailbox.c")

        tmp.replace(archive)

    print("package_lab06: PASS")
    print(f"created: {archive.name}")
    print("contains exactly:")
    print(f"  {member}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
