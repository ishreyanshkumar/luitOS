# Luit syscall ABI — version 1

This document is the contract between user programs and the kernel. The
kernel side and the user stubs are both **generated** from
`kernel/syscall.tbl` by `tools/gensyscalls.py` — that table is the single
source of truth, and this file is its human-readable mirror.

## Calling convention

RISC-V standard: syscall **number in `a7`**, arguments in `a0`–`a5`, `ecall`,
result in `a0`. Negative return values are errors (the baseline uses `-1`
uniformly; per-error codes are a possible future ABI revision).

The kernel never trusts a user pointer. Every pointer argument crosses
through `copyin`/`copyout`/`copyinstr`, which walk the user page table and
refuse anything unmapped, kernel-owned, or non-`PTE_U`.

## Versioning rules

* **Adding** a syscall with a new number: allowed within a version.
* **Renumbering or changing the signature** of an existing syscall: an ABI
  break. Bump the version here, note it in the changelog below, and expect
  every user binary to need a rebuild.
* Number 17 is a permanent gap (historical; kept so downstream forks that
  claimed it don't collide).
* Labs that add syscalls (trace, sysinfo, sigalarm, mmap…) add rows to
  `syscall.tbl` — they do not edit generated files.

## Syscall table (v1)

| # | name | signature | notes |
|---|------|-----------|-------|
| 1 | fork | `int fork(void)` | returns child pid / 0 in child |
| 2 | exit | `void exit(int status)` | does not return |
| 3 | wait | `int wait(int *status)` | status may be 0 |
| 4 | pipe | `int pipe(int fd[2])` | fd[0]=read, fd[1]=write |
| 5 | read | `int read(int fd, void *buf, int n)` | 0 = EOF |
| 6 | kill | `int kill(int pid)` | marks killed; dies at next trap |
| 7 | exec | `int exec(char *path, char **argv)` | only returns on failure |
| 8 | fstat | `int fstat(int fd, struct stat *st)` | |
| 9 | chdir | `int chdir(char *path)` | |
| 10 | dup | `int dup(int fd)` | lowest free fd |
| 11 | getpid | `int getpid(void)` | |
| 12 | sbrk | `char *sbrk(int n)` | returns OLD break |
| 13 | sleep | `int sleep(int ticks)` | tick ≈ 100 ms |
| 14 | uptime | `int uptime(void)` | ticks since boot |
| 15 | open | `int open(char *path, int omode)` | see `kernel/fcntl.h` |
| 16 | write | `int write(int fd, void *buf, int n)` | |
| 18 | unlink | `int unlink(char *path)` | refuses non-empty dirs |
| 19 | link | `int link(char *old, char *new)` | files only, same device |
| 20 | mkdir | `int mkdir(char *path)` | |
| 21 | close | `int close(int fd)` | |
| 22 | freepages | `int freepages(void)` | Luit extra: test/observability hook |
| 23 | procstat | `int procstat(struct pstat *t, int max)` | Luit extra: backs `ps` |

## File descriptors

`0`/`1`/`2` are a **convention established by init**, not kernel magic: init
opens `/console` (a `T_DEV` inode created by mkfs) and calls `dup` twice.
Nothing in the kernel special-cases those numbers — a hidden test replaces
them to make sure.

## Changelog

* **v1** (Teaching Base 1.0): initial frozen ABI, 22 syscalls.
