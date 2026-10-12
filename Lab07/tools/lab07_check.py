#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "LAB07_RELEASE.json"
EXPECTED_TODOS = [f"S{i}" for i in range(1, 7)]
SOURCE_SUFFIXES = {".c", ".h", ".S", ".s", ".py", ".sh", ".ld", ".mk", ".md", ".txt", ".tex"}
SOURCE_NAMES = {"Makefile"}
GENERATED_SOURCE = {
    "kernel/syscallnums.h",
    "kernel/syscalltab.h",
    "kernel/initcode_blob.S",
    "user/usys.S",
}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def normalized_proc_scaffold(text: str) -> str | None:
    for label in EXPECTED_TODOS:
        rx = re.compile(
            rf"(?ms)(^[ \t]*/\* TODO-BEGIN {label}:.*?\*/[ \t]*\n)"
            rf".*?"
            rf"(^[ \t]*/\* TODO-END {label} \*/[ \t]*$)"
        )
        matches = list(rx.finditer(text))
        if len(matches) != 1:
            return None
        text = rx.sub(lambda m: m.group(1) + f"<EDITABLE-{label}>\n" + m.group(2), text, count=1)

    hrx = re.compile(
        r"(?ms)(^[ \t]*/\* LAB7-HELPERS-BEGIN \*/[ \t]*\n)"
        r".*?"
        r"(^[ \t]*/\* LAB7-HELPERS-END \*/[ \t]*$)"
    )
    if len(list(hrx.finditer(text))) != 1:
        return None
    return hrx.sub(lambda m: m.group(1) + "<EDITABLE-HELPERS>\n" + m.group(2), text, count=1)


def source_snapshot(root: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(root).as_posix()
        parts = Path(rel).parts
        if any(part in {".git", "__pycache__"} for part in parts):
            continue
        if rel in {"kernel/proc.c", "LAB07_RELEASE.json"} or rel in GENERATED_SOURCE:
            continue
        if path.name == "LLM_LOG.md":
            continue
        if rel.endswith("_Lab07.zip") or rel.startswith(".lab07_package_"):
            continue
        if path.name in SOURCE_NAMES or path.suffix in SOURCE_SUFFIXES:
            out[rel] = sha256(path)
    return dict(sorted(out.items()))


def ok(msg: str) -> None:
    print(f"[PASS] {msg}")


def fail(msg: str) -> None:
    print(f"[FAIL] {msg}")


def main() -> int:
    print("=== CS3106L Lab 7 release check ===")
    errors = 0

    if not MANIFEST.is_file():
        fail("LAB07_RELEASE.json is missing; re-extract the supplied Lab 7 repository")
        return 1
    try:
        m = json.loads(MANIFEST.read_text(encoding="utf-8"))
    except Exception as e:
        fail(f"cannot parse LAB07_RELEASE.json: {e}")
        return 1

    if m.get("lab") != 7 or m.get("editable") != ["kernel/proc.c"]:
        fail("release manifest does not describe the expected Lab 7 contract")
        errors += 1
    else:
        ok("kernel/proc.c is the only editable implementation file")

    baseline = m.get("baseline_source_sha256")
    if not isinstance(baseline, dict) or not baseline:
        fail("source-tree baseline is missing or invalid")
        errors += 1
    else:
        current = source_snapshot(ROOT)
        missing = sorted(set(baseline) - set(current))
        unexpected = sorted(set(current) - set(baseline))
        changed = sorted(rel for rel in set(baseline) & set(current) if baseline[rel] != current[rel])
        for rel in missing:
            fail(f"protected source file missing: {rel}"); errors += 1
        for rel in unexpected:
            fail(f"unexpected source-like file added outside kernel/proc.c: {rel}"); errors += 1
        for rel in changed:
            fail(f"protected source file changed: {rel}"); errors += 1
        if not (missing or unexpected or changed):
            ok(f"protected source tree intact ({len(baseline)} files)")

    source = ROOT / "kernel/proc.c"
    if not source.is_file():
        fail("kernel/proc.c is missing")
        errors += 1
    else:
        text = source.read_text(encoding="utf-8", errors="replace")
        begins = re.findall(r"TODO-BEGIN\s+(S[1-6])\b", text)
        ends = re.findall(r"TODO-END\s+(S[1-6])\b", text)
        if begins == EXPECTED_TODOS and ends == EXPECTED_TODOS:
            ok("TODO markers S1-S6 are present exactly once and in order")
        else:
            fail(f"TODO marker sequence changed: begins={begins}, ends={ends}")
            errors += 1

        if text.count("/* LAB7-HELPERS-BEGIN */") == 1 and text.count("/* LAB7-HELPERS-END */") == 1:
            ok("optional helper region is intact")
        else:
            fail("helper-region markers must be preserved exactly once")
            errors += 1

        scaffold = normalized_proc_scaffold(text)
        expected = m.get("proc_scaffold_sha256")
        if scaffold is None or not isinstance(expected, str):
            fail("cannot validate protected scaffold of kernel/proc.c")
            errors += 1
        elif sha256_text(scaffold) != expected:
            fail("kernel/proc.c changed outside the six TODO/helper regions")
            errors += 1
        else:
            ok("kernel/proc.c protected scaffold is unchanged")

    # The two new ABI rows are fixed infrastructure, not part of the task.
    tbl = (ROOT / "kernel/syscall.tbl").read_text(encoding="utf-8", errors="replace")
    for num, name, handler in [(29, "settickets", "sys_settickets"), (30, "schedinfo", "sys_schedinfo")]:
        rx = rf"(?m)^\s*{num}\s+{name}\s+{handler}\s*(?:#.*)?$"
        if re.search(rx, tbl): ok(f"syscall ABI intact: {name}={num}")
        else: fail(f"syscall ABI mismatch for {name}"); errors += 1

    required = [
        "kernel/schedinfo.h", "kernel/schedlab.c",
        "user/stride_api.c", "user/stride_share.c", "user/stride_wakeup.c", "user/stride_smp.c",
        "tests/grade_lab07.py", "tests/lab07_stride.sh", "tools/package_lab07.py",
        "docs/CS3106L_Lab07_Handout.pdf",
    ]
    for rel in required:
        if (ROOT / rel).is_file(): ok(f"present: {rel}")
        else: fail(f"required Lab 7 file missing: {rel}"); errors += 1

    if errors:
        print(f"LAB7 release check: FAIL ({errors} issue(s))")
        return 1
    print("LAB7 release check: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
