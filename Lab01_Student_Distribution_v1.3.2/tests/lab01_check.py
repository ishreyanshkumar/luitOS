#!/usr/bin/env python3
"""Validate the Lab 1 release structure and protected-file integrity.

This is a student-facing sanity check, not the grading program. It deliberately
allows changes only in the four implementation files and the lab01 evidence
folder. Generated build products are ignored.
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "tests" / "lab01_manifest.json"

EDITABLE = {
    "user/sleep.c",
    "user/pingpong.c",
    "user/pstree.c",
    "tools/syscallmap.py",
}

TODO_LABELS = {
    "user/sleep.c": ["S1", "S2", "S3"],
    "user/pingpong.c": ["P1", "P2", "P3", "P4"],
    "user/pstree.c": ["T1", "T2", "T3", "T4", "T5", "T6", "T7"],
    "tools/syscallmap.py": ["A1", "A2", "A3", "A4", "A5", "A6"],
}

REQUIRED = {
    *EDITABLE,
    "tools/package_lab01.py",
    "kernel/pstat.h",
    "kernel/proc.c",
    "lab01/README.txt",
    "lab01/report.tex",
    "lab01/gdb-trace.txt",
    "lab01/LLM_LOG.md",
    "LAB01_RELEASE.txt",
    "README.md",
    "docs/LLM_POLICY.md",
    "docs/labs/LUIT_Lab01_Student_Handout.pdf",
}

USER_BINARIES = {
    "init", "sh", "echo", "cat", "ls", "mkdir", "rm", "wc", "grep",
    "kill", "ln", "ps", "meminfo", "vdemo", "sleep", "pingpong",
    "pstree", "usertests", "forktest",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def ignored(relative: str) -> bool:
    path = Path(relative)

    # Windows may attach Mark-of-the-Web metadata to downloaded files.
    # When such archives are handled through WSL, NTFS alternate data streams
    # can appear as ordinary files named "<original>:Zone.Identifier".
    # They do not alter the protected source file and must not fail this check.
    if path.name.endswith(":Zone.Identifier"):
        return True

    # Ignore common host-OS directory metadata as well.
    if path.name in {".DS_Store", "Thumbs.db", "desktop.ini"}:
        return True

    if relative in EDITABLE or relative.startswith("lab01/"):
        return True
    if relative == "tests/lab01_manifest.json":
        return True
    if relative.endswith("_Lab01.zip"):
        return True
    if any(part in {".git", "__pycache__"} for part in path.parts):
        return True
    if path.suffix in {".o", ".d", ".pyc", ".aux", ".log", ".toc"}:
        return True
    if relative in {
        "fs.img", "kernel.elf", "kernel.asm", "kernel.sym", "mkfs/mkfs",
        "kernel/syscallnums.h", "kernel/syscalltab.h",
        "kernel/initcode_blob.S", "user/usys.S", "user/initcode",
        "user/initcode.out",
    }:
        return True
    if len(path.parts) == 2 and path.parts[0] == "user" and path.name in USER_BINARIES:
        return True
    return False


def load_manifest() -> dict[str, str]:
    try:
        data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise RuntimeError("tests/lab01_manifest.json is missing") from error
    except json.JSONDecodeError as error:
        raise RuntimeError(f"invalid manifest JSON: {error}") from error
    if not isinstance(data, dict) or not all(
        isinstance(key, str) and isinstance(value, str) for key, value in data.items()
    ):
        raise RuntimeError("manifest must be a JSON object of path/hash pairs")
    return data


def check_required(errors: list[str]) -> None:
    for relative in sorted(REQUIRED):
        if not (ROOT / relative).is_file():
            errors.append(f"missing required file: {relative}")
    for forbidden in ("staff", "TA_GUIDE.md", "docs/COURSE_OPS.md"):
        if (ROOT / forbidden).exists():
            errors.append(f"instructor-only path must not be present: {forbidden}")


def check_todos(errors: list[str]) -> None:
    for relative, expected in TODO_LABELS.items():
        path = ROOT / relative
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        begins = re.findall(r"TODO-BEGIN\s+([A-Z][0-9]+)\b", text)
        ends = re.findall(r"TODO-END\s+([A-Z][0-9]+)\b", text)
        if begins != expected:
            errors.append(
                f"{relative}: TODO-BEGIN labels are {begins}; expected {expected}"
            )
        if ends != expected:
            errors.append(
                f"{relative}: TODO-END labels are {ends}; expected {expected}"
            )


def check_release_contract(errors: list[str]) -> None:
    pstat = ROOT / "kernel" / "pstat.h"
    if pstat.is_file():
        text = pstat.read_text(encoding="utf-8", errors="replace")
        if not re.search(r"\bint\s+ppid\s*;", text):
            errors.append("kernel/pstat.h: required int ppid field is absent")

    makefile = ROOT / "Makefile"
    if makefile.is_file():
        text = makefile.read_text(encoding="utf-8", errors="replace")
        for program in ("user/sleep", "user/pingpong", "user/pstree"):
            if program not in text:
                errors.append(f"Makefile: UPROGS is missing {program}")

    for relative in ("tools/syscallmap.py", "tools/package_lab01.py", "tests/lab01_check.py"):
        path = ROOT / relative
        if not path.is_file():
            continue
        try:
            compile(path.read_text(encoding="utf-8"), relative, "exec")
        except SyntaxError as error:
            errors.append(f"{relative}: Python syntax error at line {error.lineno}: {error.msg}")


def check_protected_files(errors: list[str]) -> None:
    try:
        manifest = load_manifest()
    except RuntimeError as error:
        errors.append(str(error))
        return

    for relative, expected_hash in sorted(manifest.items()):
        path = ROOT / relative
        if not path.is_file():
            errors.append(f"protected file missing: {relative}")
            continue
        actual = sha256(path)
        if actual != expected_hash:
            errors.append(f"protected file changed: {relative}")

    current: set[str] = set()
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(ROOT).as_posix()
        if ignored(relative):
            continue
        current.add(relative)

    unexpected = sorted(current - set(manifest))
    for relative in unexpected:
        errors.append(f"unexpected protected-area file: {relative}")


def main() -> int:
    errors: list[str] = []
    check_required(errors)
    check_todos(errors)
    check_release_contract(errors)
    check_protected_files(errors)

    if errors:
        print("lab01-check: FAILED", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print("lab01-check: PASS")
    print("  skeleton files and TODO markers are present")
    print("  protected release files match the instructor manifest")
    print("  Lab 1 ppid/build/packaging contract is intact")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
