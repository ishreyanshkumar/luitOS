# GENERATED from kernel/syscall.tbl by tools/gensyscalls.py.
# The ENTIRE user->kernel interface: number in a7, ecall, result in a0.
.macro SYSCALL name, num
.globl \name
\name:
        li a7, \num
        ecall
        ret
.endm

SYSCALL fork, 1
SYSCALL exit, 2
SYSCALL wait, 3
SYSCALL pipe, 4
SYSCALL read, 5
SYSCALL kill, 6
SYSCALL exec, 7
SYSCALL fstat, 8
SYSCALL chdir, 9
SYSCALL dup, 10
SYSCALL getpid, 11
SYSCALL sbrk, 12
SYSCALL sleep, 13
SYSCALL uptime, 14
SYSCALL open, 15
SYSCALL write, 16
SYSCALL unlink, 18
SYSCALL link, 19
SYSCALL mkdir, 20
SYSCALL close, 21
SYSCALL freepages, 22
SYSCALL procstat, 23
