#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "LAB06_RELEASE.json"
EXPECTED_TODOS = ["M1", "M2", "M3", "M4", "M5"]
SOURCE_SUFFIXES = {".c", ".h", ".S", ".s", ".py", ".ld", ".mk", ".md", ".txt"}
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


def normalized_mailbox_scaffold(text: str) -> str | None:
    for label in EXPECTED_TODOS:
        rx = re.compile(
            rf"(?ms)(^[ \t]*/\* TODO-BEGIN {label}:[^\n]*\*/[ \t]*\n)"
            rf".*?"
            rf"(^[ \t]*/\* TODO-END {label} \*/[ \t]*$)"
        )
        if len(list(rx.finditer(text))) != 1:
            return None
        text = rx.sub(lambda m: m.group(1) + f"<EDITABLE-{label}>\n" + m.group(2), text, count=1)
    hrx = re.compile(
        r"(?ms)(^[ \t]*/\* LAB6-HELPERS-BEGIN \*/[ \t]*\n)"
        r".*?"
        r"(^[ \t]*/\* LAB6-HELPERS-END \*/[ \t]*$)"
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
        if any(part in {".git", ".lab06_backup", "__pycache__"} for part in parts):
            continue
        if rel in {"kernel/mailbox.c", "LAB06_RELEASE.json"} or rel in GENERATED_SOURCE:
            continue
        if path.name == "LLM_LOG.md":
            continue
        if rel.endswith("_Lab06.zip"):
            continue
        if path.name in SOURCE_NAMES or path.suffix in SOURCE_SUFFIXES:
            out[rel] = sha256(path)
    return dict(sorted(out.items()))


def ok(msg: str) -> None:
    print(f"[PASS] {msg}")


def fail(msg: str) -> None:
    print(f"[FAIL] {msg}")


def main() -> int:
    print("=== CS3106L Lab 6 release check ===")
    errors = 0
    if not MANIFEST.is_file():
        fail("LAB06_RELEASE.json is missing; use the supplied installer on the intended release tree")
        return 1
    try:
        m = json.loads(MANIFEST.read_text(encoding="utf-8"))
    except Exception as e:
        fail(f"cannot parse LAB06_RELEASE.json: {e}")
        return 1

    if m.get("lab") != 6 or m.get("editable") != ["kernel/mailbox.c"]:
        fail("LAB06_RELEASE.json does not describe the expected Lab 6 release contract")
        errors += 1
    else:
        ok("release contract identifies kernel/mailbox.c as the only editable implementation file")

    protected = m.get("protected_sha256")
    if not isinstance(protected, dict) or not protected:
        fail("protected-file manifest is missing or invalid")
        errors += 1
        protected = {}

    for rel, expected in sorted(protected.items()):
        path = ROOT / rel
        if not path.is_file():
            fail(f"protected file missing: {rel}")
            errors += 1
        elif sha256(path) != expected:
            fail(f"protected file changed: {rel}")
            errors += 1
        else:
            ok(f"protected file unchanged: {rel}")

    baseline = m.get("baseline_source_sha256")
    if not isinstance(baseline, dict) or not baseline:
        fail("full source-tree baseline manifest is missing or invalid")
        errors += 1
    else:
        current = source_snapshot(ROOT)
        missing = sorted(set(baseline) - set(current))
        unexpected = sorted(set(current) - set(baseline))
        changed = sorted(rel for rel in set(baseline) & set(current) if baseline[rel] != current[rel])
        for rel in missing:
            fail(f"baseline source file missing: {rel}")
            errors += 1
        for rel in unexpected:
            fail(f"unexpected source-like file added outside kernel/mailbox.c: {rel}")
            errors += 1
        for rel in changed:
            fail(f"source file changed outside kernel/mailbox.c: {rel}")
            errors += 1
        if not (missing or unexpected or changed):
            ok(f"full source-tree integrity intact ({len(baseline)} protected source files)")

    source = ROOT / "kernel/mailbox.c"
    if not source.is_file():
        fail("kernel/mailbox.c is missing")
        errors += 1
    else:
        text = source.read_text(encoding="utf-8", errors="replace")
        begins = re.findall(r"TODO-BEGIN\s+(M[1-5])\b", text)
        ends = re.findall(r"TODO-END\s+(M[1-5])\b", text)
        if begins == EXPECTED_TODOS and ends == EXPECTED_TODOS:
            ok("TODO markers M1--M5 are present exactly once and in order")
        else:
            fail(f"TODO marker sequence changed: begins={begins}, ends={ends}")
            errors += 1

        if text.count("/* LAB6-HELPERS-BEGIN */") == 1 and text.count("/* LAB6-HELPERS-END */") == 1:
            ok("optional helper-region markers are intact")
        else:
            fail("helper-region markers must be preserved exactly once")
            errors += 1

        scaffold = normalized_mailbox_scaffold(text)
        expected_scaffold = m.get("mailbox_scaffold_sha256")
        if scaffold is None or not isinstance(expected_scaffold, str):
            fail("cannot validate protected scaffold of kernel/mailbox.c")
            errors += 1
        elif sha256_text(scaffold) != expected_scaffold:
            fail("protected scaffold of kernel/mailbox.c changed outside TODO/helper regions")
            errors += 1
        else:
            ok("supplied syscall wrappers/validation/scaffold are unchanged")

        forbidden = {
            "compiler atomic builtins": r"__sync_|__atomic_",
            "manual interrupt manipulation": r"\b(?:push_off|pop_off|intr_off|intr_on)\s*\(",
            "busy-yield workaround": r"\byield\s*\(",
        }
        for name, rx in forbidden.items():
            if re.search(rx, text):
                fail(f"kernel/mailbox.c contains forbidden {name}")
                errors += 1
            else:
                ok(f"no forbidden {name}")

        if re.search(r"\bacquire\s*\(", text) and re.search(r"\brelease\s*\(", text):
            ok("mailbox implementation uses the existing spinlock API")
        else:
            print("[INFO] acquire/release not both visible yet (expected before implementation is complete)")

        if re.search(r"\bsleep\s*\(", text) and re.search(r"\bwakeup\s*\(", text):
            ok("mailbox implementation uses the existing sleep/wakeup API")
        else:
            print("[INFO] sleep/wakeup not both visible yet (expected before implementation is complete)")

    # Re-check ABI rows against the install manifest.
    tbl_path = ROOT / "kernel/syscall.tbl"
    if not tbl_path.is_file():
        fail("kernel/syscall.tbl is missing")
        errors += 1
    else:
        tbl = tbl_path.read_text(encoding="utf-8", errors="replace")
        syscalls = m.get("syscalls", {})
        if set(syscalls) != {"mbox_send", "mbox_recv", "mbox_close"}:
            fail("release manifest has an unexpected mailbox syscall set")
            errors += 1
        for name, number in syscalls.items():
            rx = rf"(?m)^\s*{number}\s+{re.escape(name)}\s+sys_{re.escape(name)}\s*(?:#.*)?$"
            if re.search(rx, tbl):
                ok(f"syscall ABI intact: {name}={number}")
            else:
                fail(f"syscall ABI mismatch for {name}")
                errors += 1

    if errors:
        print(f"LAB6 release check: FAIL ({errors} issue(s))")
        return 1
    print("LAB6 release check: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
