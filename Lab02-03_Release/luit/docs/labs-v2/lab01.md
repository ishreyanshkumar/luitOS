# Lab 1 — Systems Comprehension & LUIT Diagnostics

*CS3106L · Dr. Satyajit Das · IIT Guwahati · double-lab week · ~6 h take-home*

> **What this lab is really about.** In the xv6 course, Lab 1 is five small
> Unix programs. Ours keeps two as a warm-up; its real purpose is to make you
> *read* the LUIT baseline — the process table, the generated syscall ABI, the
> fd layer — and build **diagnostic tools that inspect a running LUIT system**.
> These cannot be copied; they only work if you understand LUIT's internals.

## 1. Educational objective
Understand the complete baseline as a reader and instrumenter before modifying
any subsystem. Navigate the source; use `procstat`/`freepages`; read generated
syscall metadata — skills every later lab needs.

## 2. Concepts covered
Processes and the process table; fork/exec/wait; file descriptors and the open-
file table; the generated ABI (syscall.tbl → numbers, dispatch, stubs); pipes;
reading a kernel from the outside through observability interfaces.

## 3. Baseline components you must read
`user/sh.c`; `kernel/proc.c` (struct proc, procstat); `kernel/pstat.h`;
`kernel/syscall.tbl` + `tools/gensyscalls.py`; `kernel/sysfile.c` (open, dup,
ofile[]); `user/ps.c`, `user/meminfo.c`.

## 4. Warm-up tasks (canonical, lightly graded)
1. `sleep n` — sleep n ticks; usage error on missing arg.
2. `pingpong` — parent/child exchange a byte over two pipes.
*(primes/find/xargs omitted: most-copied xv6 programs, teach nothing about LUIT.)*

## 5. Main implementation tasks
**A — `pstree`**: print the process tree from `init`, requiring you to extend
`struct pstat` and `procstat()` to return `ppid`.
**B — `fdinfo <pid>`**: per-descriptor type/inode/offset via a new syscall
`fdstat(pid, fd, struct fdinfo*)`.
**C — `syscalls`**: print the live syscall table via a new syscall
`abimeta(struct abinfo*, int)` reading the generated metadata.
**D — `pipeprof cmd | cmd`**: run a pipeline, report per-stage ticks and bytes
(bytes from your fdstat offsets; time from uptime()).

## 6. Requirements that differ from xv6
No public xv6 Lab-1 solution provides a process *tree* (needs ppid), an fd
inspector (new syscall over ofile[]), an ABI reader (LUIT's generated metadata),
or a pipeline profiler. Tasks B/C require adding syscalls via the generated table.

## 7. Required interfaces and system calls
Extend `procstat` (+ppid). New `fdstat(int,int,struct fdinfo*)`,
`abimeta(struct abinfo*,int)`. Both via syscall.tbl (never hand-edit generated files).

## 8. Required data structures
`struct fdinfo { int type,inum,off,readable,writable; }`;
`struct abinfo { int num; char name[16]; }`.

## 9. Concurrency and locking requirements
Read the target under its `p->lock`; copy to a local, release lock, THEN
copyout. Never hold p->lock across copyout. pstree tolerates the table changing
mid-scan.

## 10. Error-handling requirements
fdstat on invalid pid/unused/closed fd → -1. abimeta with max<=0 → -1; small max
returns only that many. All tools handle a target exiting during inspection.

## 11. Integration with previous labs
None (first lab). The `ppid` and `fdstat` you add are reused in Lab 2 tracing
and Lab 3's shared page.

## 12. Public tests (`make grade LAB=1`)
pstree shows init(1) + sh nesting; fdinfo of a redirected process shows fd 1 as a
file with nonzero offset; syscalls lists fork/open/procstat + your new calls;
pipeprof reports two stages with plausible byte counts.

## 13. Hidden tests
fdstat(pid,99)→-1; fdstat of a pipe end reports type=pipe; ppid correct after a
grandchild reparents to init; abimeta(max=3) returns exactly 3, no overflow;
pstree under a 10-child storm doesn't crash and is internally consistent.

## 14. Performance / correctness measurement
Report ticks to inspect an N-process system with pstree for N∈{2,8,32}; explain
the scaling.

## 15. Required report (≤2 pages)
Where ppid lives; your fdinfo design; the copyout-locking argument; the pstree
measurement; one failed approach.

## 16. Viva questions
Where is a parent pid, and why not in baseline pstat? What does open() do to
ofile[] that fdstat reads? Why copyout after releasing p->lock? How does
syscall.tbl become both dispatch and stub?

## 17. Expected workload
~6h: 2h reading, 3h four tools + two syscalls, 1h measurement/report.

## 18. Starter code provided
Skeletons for the four programs; pstat.h with a marked ppid TODO; commented stub
rows in syscall.tbl.

## 19. Staff-only reference requirements
ppid in pstat; fdstat reading ofile[fd] under lock; abimeta from generated
syscall_names[]; a reparented-grandchild harness.

## 20. Common incorrect approaches
Holding p->lock across copyout; reading ofile[] without the lock; hardcoding the
syscall list instead of abimeta (fails the hidden dummy-syscall test).

## 21. Suggested rubric (100)
Warm-up 10 · pstree 20 · fdinfo 20 · syscalls 15 · pipeprof 15 · report 12 · viva 8.

## 22. LLM-use declaration
Appendix: prompts to understand procstat/ofile[]; accepted/rejected suggestions;
LLM-influenced code; verification. Explaining ofile[] is fine; a pasted fdstat
you can't defend is not.

## 23. Anti-copying check
No public xv6 pstree/fdinfo/abimeta. The hidden dummy-syscall test defeats a
hardcoded list. The copyout-locking viva reveals real understanding.
