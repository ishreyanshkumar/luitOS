# LUIT syscall ABI — version 1

This document defines the contract between user programs and the kernel. The
kernel dispatch table and user stubs are generated from `kernel/syscall.tbl`
by `tools/gensyscalls.py`; the table is the single source of truth.

## Calling convention

The ABI follows the RISC-V convention: the syscall number is placed in `a7`,
arguments are passed in `a0`–`a5`, `ecall` enters the kernel, and the return
value is placed in `a0`. Negative values indicate failure.

The kernel never dereferences user pointers directly. Pointer arguments pass
through `copyin`, `copyout`, or `copyinstr`, which validate the user page table
mapping and require `PTE_U`.

## Versioning rules

- Adding a syscall with a new number is compatible within the current version.
- Renumbering a syscall or changing its signature is an ABI break.
- Number 17 remains unused for compatibility.
- Edit `kernel/syscall.tbl`, not generated files.

## Syscall table

| # | name | signature | notes |
|---|---|---|---|
| 1 | fork | `int fork(void)` | child PID in parent, 0 in child |
| 2 | exit | `void exit(int status)` | does not return |
| 3 | wait | `int wait(int *status)` | status pointer may be null |
| 4 | pipe | `int pipe(int fd[2])` | read and write descriptors |
| 5 | read | `int read(int fd, void *buf, int n)` | 0 indicates EOF |
| 6 | kill | `int kill(int pid)` | marks a process for termination |
| 7 | exec | `int exec(char *path, char **argv)` | returns only on failure |
| 8 | fstat | `int fstat(int fd, struct stat *st)` | file status |
| 9 | chdir | `int chdir(char *path)` | change working directory |
| 10 | dup | `int dup(int fd)` | lowest available descriptor |
| 11 | getpid | `int getpid(void)` | process identifier |
| 12 | sbrk | `char *sbrk(int n)` | returns the previous break |
| 13 | sleep | `int sleep(int ticks)` | sleep for timer ticks |
| 14 | uptime | `int uptime(void)` | ticks since boot |
| 15 | open | `int open(char *path, int omode)` | flags in `kernel/fcntl.h` |
| 16 | write | `int write(int fd, void *buf, int n)` | write bytes |
| 18 | unlink | `int unlink(char *path)` | remove a directory entry |
| 19 | link | `int link(char *old, char *new)` | create a hard link |
| 20 | mkdir | `int mkdir(char *path)` | create a directory |
| 21 | close | `int close(int fd)` | close a descriptor |
| 22 | freepages | `int freepages(void)` | report available pages |
| 23 | procstat | `int procstat(struct pstat *t, int max)` | process snapshot |

## File descriptors

Descriptors 0, 1, and 2 are established by `init`: it opens `/console` and
duplicates the descriptor twice. The kernel does not special-case these values.

## Changelog

- **v1:** initial ABI with 22 active syscall numbers and one reserved gap.
