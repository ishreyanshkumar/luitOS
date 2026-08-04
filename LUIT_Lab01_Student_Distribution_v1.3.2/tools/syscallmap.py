#!/usr/bin/env python3
"""Lab 1 starter: verify Luit's generated syscall ABI.

Complete the marked TODO sections. Use only the Python 3 standard library.
Run this program from anywhere; paths are resolved from the repository root.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SYSCALL_TABLE = ROOT / "kernel" / "syscall.tbl"
SYSCALL_NUMBERS = ROOT / "kernel" / "syscallnums.h"
SYSCALL_DISPATCH = ROOT / "kernel" / "syscalltab.h"
USER_STUBS = ROOT / "user" / "usys.S"


class InputError(ValueError):
    """Expected malformed/missing ABI input; display without a traceback."""


def parse_syscall_table(path: Path) -> list[tuple[int, str, str]]:
    """Return (number, user_name, kernel_handler) rows."""
    # TODO-BEGIN A1: parse comments/blank lines and validate every row.
    table = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            # Skip empty lines or comments
            if not line or line.startswith('#'):
                continue
            
            parts = line.split()
            if len(parts) != 3:
                raise InputError(f"malformed non-comment row: {line}")
            
            try:
                num = int(parts[0])
            except ValueError:
                raise InputError(f"malformed non-comment row: {line}")
                
            table.append((num, parts[1], parts[2]))
    return table
    # TODO-END A1



def parse_syscall_numbers(path: Path) -> tuple[dict[str, int], int]:
    """Return SYS_name definitions and NSYSCALL."""
    # TODO-BEGIN A2: parse generated #define lines.
    numbers = {}
    nsyscall = -1
    with open(path) as f:
        for line in f:
            line = line.strip()
            # Matches: #define SYS_fork 1   OR   #define NSYSCALL 24
            match = re.match(r'^#define\s+(SYS_([a-zA-Z0-9_]+)|NSYSCALL)\s+(\d+)$', line)
            if match:
                if match.group(1) == 'NSYSCALL':
                    nsyscall = int(match.group(3))
                else:
                    name = match.group(2)
                    numbers[name] = int(match.group(3))
    
    if nsyscall == -1:
        raise InputError("NSYSCALL missing")
    return numbers, nsyscall
    # TODO-END A2



def parse_syscalltab(path: Path) -> tuple[dict[int, str], dict[int, str]]:
    """Return dispatch handlers and syscall_names entries indexed by number."""
    # TODO-BEGIN A3: parse both generated arrays in syscalltab.h.
    handlers = {}
    names = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            # Matches: [1] sys_fork,
            match_handler = re.match(r'^\[(\d+)\]\s+(sys_\w+),$', line)
            if match_handler:
                handlers[int(match_handler.group(1))] = match_handler.group(2)
                continue
            
            # Matches: [1] "fork",
            match_name = re.match(r'^\[(\d+)\]\s+"(\w+)",$', line)
            if match_name:
                names[int(match_name.group(1))] = match_name.group(2)
                
    return handlers, names
    # TODO-END A3



def parse_user_stubs(path: Path) -> dict[str, int]:
    """Return generated SYSCALL name, number stubs."""
    # TODO-BEGIN A4: parse every generated SYSCALL invocation.
    stubs = {}
    with open(path) as f:
        for line in f:
            # Matches: SYSCALL fork, 1
            match = re.match(r'^SYSCALL\s+(\w+),\s*(\d+)$', line.strip())
            if match:
                stubs[match.group(1)] = int(match.group(2))
    return stubs
    # TODO-END A4



def validate(
    table: list[tuple[int, str, str]],
    numbers: dict[str, int],
    nsyscall: int,
    handlers: dict[int, str],
    names: dict[int, str],
    stubs: dict[str, int],
) -> list[str]:
    """Return every detected consistency error; do not stop at the first."""
    errors: list[str] = []

    # TODO-BEGIN A5:
    seen_nums = set()
    seen_names = set()
    highest_num = 0

    for num, name, handler in table:
        if num <= 0:
            errors.append(f"non-positive syscall number: {num}")
        if num in seen_nums:
            errors.append(f"duplicate syscall number: {num}")
        if name in seen_names:
            errors.append(f"duplicate syscall name: {name}")
            
        seen_nums.add(num)
        seen_names.add(name)
        if num > highest_num:
            highest_num = num

        # Check for missing/mismatched values in generated files
        if name not in numbers or numbers[name] != num:
            errors.append(f"missing or incorrect #define SYS_{name} in syscallnums.h")
        if num not in handlers or handlers[num] != handler:
            errors.append(f"missing or mismatched kernel handler for {name} in syscalltab.h")
        if num not in names or names[num] != name:
            errors.append(f"missing or mismatched syscall-name entry for {name} in syscalltab.h")
        if name not in stubs or stubs[name] != num:
            errors.append(f"missing or mismatched SYSCALL {name}, {num} stub in usys.S")

    # Check NSYSCALL
    if nsyscall != highest_num + 1:
        errors.append(f"incorrect NSYSCALL: {nsyscall}")

    # Check for EXTRA generated things that aren't in the source table
    for name, num in numbers.items():
        if num not in seen_nums:
            errors.append(f"extra generated number SYS_{name}={num}")
    for num, handler in handlers.items():
        if num not in seen_nums:
            errors.append(f"extra generated handler {handler} at {num}")
    for num, name in names.items():
        if num not in seen_nums:
            errors.append(f"extra generated name {name} at {num}")
    for name, num in stubs.items():
        if num not in seen_nums:
            errors.append(f"extra generated user stub {name}, {num}")
    # TODO-END A5


    return errors


def print_map(
    table: list[tuple[int, str, str]], nsyscall: int, stubs: dict[str, int]
) -> None:
    """Print every number from 1 through NSYSCALL-1, including gaps."""
    # TODO-BEGIN A6: derive and print the table; do not hardcode ABI values.
    print(f"{'NUM':<3} {'NAME':<10} {'HANDLER':<14} USER-STUB")
    
    # Create a quick dictionary to look up by number
    lookup = {num: (name, handler) for num, name, handler in table}
    
    # Loop from 1 to NSYSCALL-1, including gaps!
    for i in range(1, nsyscall):
        if i in lookup:
            name, handler = lookup[i]
            # Verify the stub exists for the "USER-STUB" column
            stub_present = "yes" if name in stubs and stubs[name] == i else "no"
            print(f"{i:<3} {name:<10} {handler:<14} {stub_present}")
        else:
            print(f"{i:<3} {'<unused>':<10} {'-':<14} -")
    # TODO-END A6



def main() -> int:
    try:
        table = parse_syscall_table(SYSCALL_TABLE)
        numbers, nsyscall = parse_syscall_numbers(SYSCALL_NUMBERS)
        handlers, names = parse_syscalltab(SYSCALL_DISPATCH)
        stubs = parse_user_stubs(USER_STUBS)
        errors = validate(table, numbers, nsyscall, handlers, names, stubs)
    except FileNotFoundError as error:
        print(
            f"syscallmap: missing {error.filename}; run `make` first",
            file=sys.stderr,
        )
        return 2
    except (InputError, OSError) as error:
        print(f"syscallmap: {error}", file=sys.stderr)
        return 2
    except NotImplementedError as error:
        print(f"syscallmap: starter incomplete: {error}", file=sys.stderr)
        return 2

    print_map(table, nsyscall, stubs)

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        print(f"syscallmap: ABI invalid ({len(errors)} error(s))", file=sys.stderr)
        return 1

    highest = max(number for number, _, _ in table)
    gaps = (nsyscall - 1) - len(table)
    print(
        f"syscallmap: ABI valid ({len(table)} calls, "
        f"highest number {highest}, {gaps} gap(s))"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
