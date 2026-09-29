#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
PACKAGE = HERE.parent


class InstallError(RuntimeError):
    pass


def fail(msg: str) -> None:
    raise InstallError(msg)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="strict")


def write(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def normalized_mailbox_scaffold(text: str) -> str:
    """Erase only the permitted editable interiors, preserving all marker lines."""
    for label in ("M1", "M2", "M3", "M4", "M5"):
        rx = re.compile(
            rf"(?ms)(^[ \t]*/\* TODO-BEGIN {label}:[^\n]*\*/[ \t]*\n)"
            rf".*?"
            rf"(^[ \t]*/\* TODO-END {label} \*/[ \t]*$)"
        )
        matches = list(rx.finditer(text))
        if len(matches) != 1:
            fail(f"starter kernel/mailbox.c has malformed editable region {label}")
        text = rx.sub(lambda m: m.group(1) + f"<EDITABLE-{label}>\n" + m.group(2), text, count=1)

    hrx = re.compile(
        r"(?ms)(^[ \t]*/\* LAB6-HELPERS-BEGIN \*/[ \t]*\n)"
        r".*?"
        r"(^[ \t]*/\* LAB6-HELPERS-END \*/[ \t]*$)"
    )
    matches = list(hrx.finditer(text))
    if len(matches) != 1:
        fail("starter kernel/mailbox.c has malformed helper region")
    return hrx.sub(lambda m: m.group(1) + "<EDITABLE-HELPERS>\n" + m.group(2), text, count=1)


def parse_syscalls(text: str):
    rows = []
    for raw in text.splitlines():
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        fields = line.split()
        if len(fields) < 3 or not fields[0].isdigit():
            fail(f"unrecognized kernel/syscall.tbl row: {raw!r}")
        rows.append((int(fields[0]), fields[1], fields[2]))
    if not rows:
        fail("kernel/syscall.tbl contains no syscall rows")
    return rows


def insert_before_endif(text: str, block: str) -> str:
    matches = list(re.finditer(r"(?m)^\s*#endif\b.*$", text))
    if matches:
        m = matches[-1]
        return text[:m.start()] + block.rstrip() + "\n\n" + text[m.start():]
    return text.rstrip() + "\n\n" + block.rstrip() + "\n"


def patch_uprogs(text: str) -> str:
    names = ("user/mbox_basic", "user/mbox_block", "user/mbox_multi", "user/mbox_stress")
    if any(name in text for name in names):
        fail("one or more mailbox user programs already appear in Makefile")
    lines = text.splitlines(keepends=True)
    start = next((i for i, line in enumerate(lines)
                  if re.match(r"^\s*UPROGS\s*[:+?]?=", line)), None)
    if start is None:
        fail("could not find UPROGS assignment in Makefile")
    end = start
    while lines[end].rstrip().endswith("\\"):
        end += 1
        if end >= len(lines):
            fail("unterminated UPROGS continuation")
    ending = "\n" if lines[end].endswith("\n") else ""
    line = lines[end].rstrip("\n")
    code, sep, comment = line.partition("#")
    code = code.rstrip() + " user/mbox_basic user/mbox_block user/mbox_multi user/mbox_stress"
    if sep:
        code += "  #" + comment
    lines[end] = code + ending
    return "".join(lines)


def patch_kernel_object(text: str) -> str:
    if "mailbox.o" in text:
        fail("mailbox.o already appears in Makefile")
    if re.search(r"wildcard\s+kernel/\*\.c", text) or re.search(r"kernel/\*\.c", text):
        return text
    patterns = [
        (r"kernel/proc\.o", "kernel/mailbox.o"),
        (r"\$\(K\)/proc\.o", "$(K)/mailbox.o"),
        (r"\$K/proc\.o", "$K/mailbox.o"),
    ]
    for pat, newtok in patterns:
        m = re.search(pat, text)
        if not m:
            continue
        line_start = text.rfind("\n", 0, m.start()) + 1
        line_end = text.find("\n", m.end())
        if line_end < 0:
            line_end = len(text)
        line = text[line_start:line_end]
        code, sep, comment = line.partition("#")
        if code.rstrip().endswith("\\"):
            pos = code.rfind("\\")
            newline = code[:pos].rstrip() + " " + newtok + " \\" + code[pos + 1:]
        else:
            newline = code.rstrip() + " " + newtok
        if sep:
            newline += "  #" + comment
        return text[:line_start] + newline + text[line_end:]
    fail("could not patch explicit kernel object list in Makefile")


def patch_main(text: str) -> str:
    rx = re.compile(r"(?m)^(?P<indent>\s*)(?P<fn>pinit|procinit)\(\);\s*$")
    hits = list(rx.finditer(text))
    if len(hits) != 1:
        fail(f"expected exactly one pinit()/procinit() line in kernel/main.c; found {len(hits)}")
    m = hits[0]
    insert = m.group(0) + "\n" + m.group("indent") + "mailboxinit();"
    return text[:m.start()] + insert + text[m.end():]


SOURCE_SUFFIXES = {".c", ".h", ".S", ".s", ".py", ".ld", ".mk", ".md", ".txt"}
SOURCE_NAMES = {"Makefile"}
GENERATED_SOURCE = {
    "kernel/syscallnums.h",
    "kernel/syscalltab.h",
    "kernel/initcode_blob.S",
    "user/usys.S",
}


def source_snapshot(root: Path) -> dict[str, str]:
    """Hash source-like release files while excluding editable/generated state."""
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


def rollback(root: Path, backup: Path, edited: tuple[str, ...], created: list[Path]) -> None:
    # Restore in-place edited files from the backup first.
    for rel in edited:
        src = backup / rel
        dst = root / rel
        if src.is_file():
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)

    # Remove files created by this installer.  Reverse order handles children first.
    for path in reversed(created):
        try:
            if path.is_file() or path.is_symlink():
                path.unlink()
        except OSError:
            pass

    try:
        if backup.exists():
            shutil.rmtree(backup)
    except OSError:
        pass


def install(root: Path) -> None:
    edited = ("Makefile", "kernel/main.c", "kernel/defs.h", "kernel/syscall.tbl", "user/ulib.h")
    backup = root / ".lab06_backup"

    destinations = {
        "kernel/mailbox.c": PACKAGE / "starter/kernel/mailbox.c",
        "kernel/mailbox.h": PACKAGE / "starter/kernel/mailbox.h",
        "user/mbox_basic.c": PACKAGE / "starter/user/mbox_basic.c",
        "user/mbox_block.c": PACKAGE / "starter/user/mbox_block.c",
        "user/mbox_stress.c": PACKAGE / "starter/user/mbox_stress.c",
        "user/mbox_multi.c": PACKAGE / "starter/user/mbox_multi.c",
        "tools/lab06_check.py": PACKAGE / "tools/lab06_check.py",
        "tools/package_lab06.py": PACKAGE / "tools/package_lab06.py",
        "tests/grade_lab06.py": PACKAGE / "tests/grade_lab06.py",
        "docs/lab06_gdb.txt": PACKAGE / "docs/lab06_gdb.txt",
    }

    # Refuse before touching the tree if any Lab 6 artifact already exists.
    conflicts = [rel for rel in destinations if (root / rel).exists()]
    for rel in ("LAB06_RELEASE.json", "LAB06_RELEASE.txt", ".lab06_backup"):
        if (root / rel).exists():
            conflicts.append(rel)
    if conflicts:
        fail("refusing to overwrite existing Lab 6 path(s): " + ", ".join(sorted(conflicts)))

    # Make sure the package itself is complete before touching the target tree.
    missing_package = [str(src.relative_to(PACKAGE)) for src in destinations.values() if not src.is_file()]
    if missing_package:
        fail("package is incomplete; missing: " + ", ".join(missing_package))

    # Compute every patched file fully in memory.  If an assumption does not hold,
    # installation stops here and the target tree is still byte-for-byte untouched.
    rows = parse_syscalls(read(root / "kernel/syscall.tbl"))
    base = max(n for n, _, _ in rows) + 1
    assigned = {"mbox_send": base, "mbox_recv": base + 1, "mbox_close": base + 2}

    tbl = read(root / "kernel/syscall.tbl").rstrip() + "\n"
    tbl += "\n# Lab 6: blocking mailboxes\n"
    tbl += f"{assigned['mbox_send']} mbox_send sys_mbox_send\n"
    tbl += f"{assigned['mbox_recv']} mbox_recv sys_mbox_recv\n"
    tbl += f"{assigned['mbox_close']} mbox_close sys_mbox_close\n"

    ulib = insert_before_endif(read(root / "user/ulib.h"), """/* Lab 6: blocking mailboxes. */
int mbox_send(int id, int value);
int mbox_recv(int id);
int mbox_close(int id);""")

    defs = insert_before_endif(read(root / "kernel/defs.h"), """/* Lab 6: blocking mailboxes. */
void mailboxinit(void);
uint64 sys_mbox_send(void);
uint64 sys_mbox_recv(void);
uint64 sys_mbox_close(void);""")

    mainc = patch_main(read(root / "kernel/main.c"))
    makefile = patch_kernel_object(patch_uprogs(read(root / "Makefile")))
    patched = {
        "Makefile": makefile,
        "kernel/main.c": mainc,
        "kernel/defs.h": defs,
        "kernel/syscall.tbl": tbl,
        "user/ulib.h": ulib,
    }

    created: list[Path] = []
    try:
        backup.mkdir()
        for rel in edited:
            dst = backup / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(root / rel, dst)

        for rel, src in destinations.items():
            dst = root / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            created.append(dst)

        for rel, text in patched.items():
            write(root / rel, text)

        protected = [
            "Makefile",
            "kernel/main.c",
            "kernel/defs.h",
            "kernel/syscall.tbl",
            "kernel/mailbox.h",
            "user/ulib.h",
            "user/mbox_basic.c",
            "user/mbox_block.c",
            "user/mbox_stress.c",
            "user/mbox_multi.c",
            "tools/lab06_check.py",
            "tools/package_lab06.py",
            "tests/grade_lab06.py",
            "docs/lab06_gdb.txt",
        ]
        release_json = root / "LAB06_RELEASE.json"
        release_txt = root / "LAB06_RELEASE.txt"
        write(release_txt,
              "CS3106L Lab 6 - Blocking Mailboxes in LUIT\n"
              "Editable implementation file: kernel/mailbox.c\n"
              f"Syscalls: send={assigned['mbox_send']} recv={assigned['mbox_recv']} close={assigned['mbox_close']}\n")
        created.append(release_txt)

        manifest = {
            "format": 2,
            "lab": 6,
            "syscalls": assigned,
            "editable": ["kernel/mailbox.c"],
            "starter_mailbox_sha256": sha256(PACKAGE / "starter/kernel/mailbox.c"),
            "mailbox_scaffold_sha256": sha256_text(
                normalized_mailbox_scaffold(read(PACKAGE / "starter/kernel/mailbox.c"))
            ),
            "protected_sha256": {rel: sha256(root / rel) for rel in protected},
            "baseline_source_sha256": source_snapshot(root),
        }
        write(release_json, json.dumps(manifest, indent=2, sort_keys=True) + "\n")
        created.append(release_json)
    except BaseException:
        rollback(root, backup, edited, created)
        raise

    print("\nLab 6 installed successfully.")
    print(f"tree: {root}")
    print("editable file: kernel/mailbox.c")
    print("next commands:")
    print("  python3 tools/lab06_check.py")
    print("  make clean && make")
    print("  python3 tests/grade_lab06.py --quick")
    print("after all tests pass:")
    print("  python3 tools/package_lab06.py YOUR_NINE_DIGIT_ROLL")


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: python3 tools/install_lab06.py /path/to/LUIT_TREE", file=sys.stderr)
        return 2
    root = Path(sys.argv[1]).resolve()
    if not root.is_dir():
        print(f"install_lab06: ERROR: not a directory: {root}", file=sys.stderr)
        return 1

    preflight = PACKAGE / "tools/lab06_preflight.py"
    rc = subprocess.run([sys.executable, str(preflight), str(root)]).returncode
    if rc != 0:
        print("install_lab06: ERROR: preflight failed; the tree was not modified", file=sys.stderr)
        return 1

    try:
        install(root)
    except InstallError as e:
        print(f"install_lab06: ERROR: {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"install_lab06: ERROR: installation failed and rollback was attempted: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
