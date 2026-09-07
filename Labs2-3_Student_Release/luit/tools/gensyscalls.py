#!/usr/bin/env python3
"""Generate kernel/syscallnums.h + user/usys.S from kernel/syscall.tbl.
One source of truth: the table. Nobody hand-edits generated files."""
import sys

rows = []
for line in open("kernel/syscall.tbl"):
    line = line.split("#")[0].strip()
    if not line:
        continue
    num, name, handler = line.split()
    rows.append((int(num), name, handler))

nums = [n for n, _, _ in rows]
assert len(nums) == len(set(nums)), "duplicate syscall number in syscall.tbl"

with open("kernel/syscallnums.h", "w") as f:
    f.write("/* GENERATED from kernel/syscall.tbl by tools/gensyscalls.py.\n"
            " * Do not edit. Add syscalls to the table instead. */\n"
            "#ifndef LUIT_SYSCALLNUMS_H\n#define LUIT_SYSCALLNUMS_H\n")
    for n, name, _ in rows:
        f.write(f"#define SYS_{name} {n}\n")
    f.write("#define NSYSCALL %d\n" % (max(nums) + 1))
    f.write("#endif\n")

with open("kernel/syscalltab.h", "w") as f:
    f.write("/* GENERATED from kernel/syscall.tbl. Included ONLY by syscall.c. */\n")
    for _, name, h in rows:
        f.write(f"extern uint64 {h}(void);\n")
    f.write("static uint64 (*syscalls[])(void) = {\n")
    for n, _, h in rows:
        f.write(f"    [{n}] {h},\n")
    f.write("};\n")
    f.write("static const char *syscall_names[] = {\n")
    for n, name, _ in rows:
        f.write(f'    [{n}] "{name}",\n')
    f.write("};\n/* silence -Wunused for the names table until Lab 3 uses it */\n")
    f.write("static inline const char *syscall_name(int n)"
            "{ return (n > 0 && n < (int)(sizeof(syscall_names)/sizeof(char*)) &&"
            " syscall_names[n]) ? syscall_names[n] : \"?\"; }\n")

with open("user/usys.S", "w") as f:
    f.write("# GENERATED from kernel/syscall.tbl by tools/gensyscalls.py.\n"
            "# The ENTIRE user->kernel interface: number in a7, ecall, result in a0.\n"
            ".macro SYSCALL name, num\n.globl \\name\n\\name:\n"
            "        li a7, \\num\n        ecall\n        ret\n.endm\n\n")
    for n, name, _ in rows:
        f.write(f"SYSCALL {name}, {n}\n")
print("gensyscalls: %d syscalls" % len(rows))
