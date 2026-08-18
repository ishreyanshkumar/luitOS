#!/usr/bin/env python3
"""Validate and create the exact roll-numbered Lab 1 submission ZIP."""
from __future__ import annotations

import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ROLL_RE = re.compile(r"^[0-9]{9}$")

SOURCE_FILES = {
    ROOT / "user" / "sleep.c": Path("user/sleep.c"),
    ROOT / "user" / "pingpong.c": Path("user/pingpong.c"),
    ROOT / "user" / "pstree.c": Path("user/pstree.c"),
    ROOT / "tools" / "syscallmap.py": Path("tools/syscallmap.py"),
}

EVIDENCE_FILES = {
    ROOT / "lab01" / "report.pdf": Path("report.pdf"),
    ROOT / "lab01" / "gdb-trace.txt": Path("gdb-trace.txt"),
    ROOT / "lab01" / "README.txt": Path("README.txt"),
    ROOT / "lab01" / "LLM_LOG.md": Path("LLM_LOG.md"),
}

TEXT_TEMPLATES = {
    ROOT / "lab01" / "README.txt": ("REPLACE_WITH",),
    ROOT / "lab01" / "gdb-trace.txt": ("REPLACE_WITH",),
    ROOT / "lab01" / "LLM_LOG.md": ("REPLACE_WITH",),
    ROOT / "lab01" / "report.tex": (
        "REPLACE",
        "WRITE YOUR ANSWER HERE",
        "WRITE HERE",
    ),
}

INCOMPLETE_SOURCE_MARKERS = (
    "not implemented",
    "raise NotImplementedError",
)


def fail(message: str) -> int:
    print(f"package_lab01: {message}", file=sys.stderr)
    return 1


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def run_checked(command: list[str], *, cwd: Path | None = None) -> None:
    try:
        subprocess.run(command, cwd=cwd, check=True)
    except FileNotFoundError as error:
        missing = error.filename or command[0]
        raise RuntimeError(f"required command not found: {missing}") from error
    except subprocess.CalledProcessError as error:
        rendered = " ".join(command)
        raise RuntimeError(f"command failed with exit status {error.returncode}: {rendered}") from error


def validate_text_templates(roll: str) -> None:
    for path, forbidden_markers in TEXT_TEMPLATES.items():
        if not path.is_file():
            raise RuntimeError(f"missing required file: {path.relative_to(ROOT)}")
        text = read_text(path)
        if roll not in text:
            raise RuntimeError(
                f"{path.relative_to(ROOT)} does not contain the supplied roll number"
            )
        for marker in forbidden_markers:
            if marker in text:
                raise RuntimeError(
                    f"{path.relative_to(ROOT)} still contains template marker: {marker}"
                )


def validate_sources() -> None:
    for source in SOURCE_FILES:
        if not source.is_file():
            raise RuntimeError(f"missing required file: {source.relative_to(ROOT)}")
        text = read_text(source)
        for marker in INCOMPLETE_SOURCE_MARKERS:
            if marker in text:
                raise RuntimeError(
                    f"{source.relative_to(ROOT)} still contains a starter implementation marker"
                )


def build_report() -> None:
    report_dir = ROOT / "lab01"
    run_checked(["make", "clean"], cwd=report_dir)
    run_checked(["make", "report.pdf"], cwd=report_dir)
    report = report_dir / "report.pdf"
    if not report.is_file() or report.stat().st_size < 1000:
        raise RuntimeError("lab01/report.pdf was not generated correctly")


def validate_release_integrity() -> None:
    run_checked([sys.executable, "tests/lab01_check.py"], cwd=ROOT)


def create_zip(roll: str) -> Path:
    files = {**SOURCE_FILES, **EVIDENCE_FILES}
    missing = [str(path.relative_to(ROOT)) for path in files if not path.is_file()]
    if missing:
        raise RuntimeError("missing required file(s): " + ", ".join(missing))

    output = ROOT / f"{roll}_Lab01.zip"
    output.unlink(missing_ok=True)
    folder_name = f"{roll}_Lab01"

    with tempfile.TemporaryDirectory(prefix="luit-lab01-") as temporary:
        staging = Path(temporary) / folder_name
        staging.mkdir()

        for source, relative in files.items():
            destination = staging / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)

        with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            for path in sorted(staging.rglob("*")):
                if path.is_file():
                    archive.write(path, path.relative_to(staging.parent))

    with zipfile.ZipFile(output) as archive:
        bad = archive.testzip()
        if bad is not None:
            output.unlink(missing_ok=True)
            raise RuntimeError(f"ZIP verification failed at {bad}")
        names = set(archive.namelist())

    expected = {str(Path(folder_name) / relative) for relative in files.values()}
    if names != expected:
        output.unlink(missing_ok=True)
        raise RuntimeError("internal error: ZIP content does not match the submission contract")

    return output


def main() -> int:
    if len(sys.argv) != 2:
        return fail("usage: python3 tools/package_lab01.py ROLL_NUMBER")

    roll = sys.argv[1]
    if not ROLL_RE.fullmatch(roll):
        return fail("roll number must contain exactly 9 decimal digits")

    try:
        validate_text_templates(roll)
        validate_sources()
        validate_release_integrity()
        build_report()
        output = create_zip(roll)
    except RuntimeError as error:
        return fail(str(error))

    print(f"Created and verified: {output.name}")
    print(f"Top-level folder: {roll}_Lab01/")
    print("Upload this one ZIP file to the official Lab 1 OneDrive file-request link.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
