# Lab 6 — Kernel Threads & Futexes

*CS3106L · Dr. Satyajit Das · IIT Guwahati · ~10 h take-home*

> **No `uthread` reuse.** The xv6 thread lab is user-level context switching plus
> a host pthread exercise. Ours builds kernel-supported threading: `clone` with a
> shared address space, `join`, and a real **futex** on which you build a user
> mutex and condition variable. No public xv6 futex lab exists.

## 1. Educational objective
Build kernel threads sharing one address space, and the futex primitive for
efficient user-space synchronization, reasoning about sleep/wakeup, lost wakeups,
and shared-resource lifetime.

## 2. Concepts covered
Threads vs processes; shared vs private address space; clone semantics; futexes;
sleep/wakeup and the lost-wakeup problem; thread-group exit; fd/AS sharing.

## 3. Baseline components to read
`kernel/proc.c` (fork, allocproc, exit, wait, sleep, wakeup); `kernel/vm.c`
(sharing vs copying a page table); Book Ch 7 §7.5–7.6 (sleep/wakeup).

## 4. Warm-up task
Minimal `clone(fn,stack)` creating a thread sharing the caller's address space;
show two threads incrementing a shared counter (racily; fixed in Task C).

## 5. Main implementation tasks
**A** clone/join/thread groups: `clone(fn,arg,stack,flags)` with CLONE_VM/FILES;
`join(tid,*retval)`; a tgid shared across clones; `gettid`.
**B** thread-group exit: process exit tears down the whole group; `texit` ends one
thread; last exit reaps the group. Document/defend.
**C** the futex: `futex_wait(addr,expected)` (atomically compare-and-sleep vs a
concurrent wake — the lost-wakeup problem, solved with the condition-lock
discipline); `futex_wake(addr,n)`; keyed by (address space, address).
**D** user mutex/CV `libfutex`: uncontended lock takes no syscall.
**E** measure: spinlock vs futex mutex under contention, {1,2,4} harts × {2,8,32}
threads: throughput and wasted spin.

## 6. Requirements that differ from xv6
Kernel clone/shared-AS, futex wait/wake keyed on user addresses, thread-group
exit, user mutex/CV on futexes — none in the public uthread lab.

## 7. Required interfaces and system calls
`clone`, `gettid`, `texit`, `join`; `futex_wait(uint64*,uint64)`, `futex_wake(uint64*,int)`.

## 8. Required data structures
Per-thread task (tgid, tid); futex wait queues keyed by (pagetable, va) — a hash
of wait lists; `libfutex` mutex{state}, cond{seq}.

## 9. Concurrency and locking requirements
futex_wait's compare-and-sleep atomic vs futex_wake: hold the futex bucket lock
across the check and the sleep. Shared AS: sbrk/faults on a shared page table
serialized. Thread-group exit doesn't race a running sibling.

## 10. Error-handling requirements
futex_wait on unmapped/kernel addr → -1 (validate via user page table); join on
bad tid → -1; clone with a bad stack → -1, no half-created thread; wake with no
waiters → 0.

## 11. Integration with previous labs
Uses the book's sleep/wakeup. **libfutex is reused by Lab 10's pressure tests.**
Lab 2 tracing can record futex waits/wakes for measurement.

## 12. Public tests (`make grade LAB=6`)
Two clones share a global; futex_wake wakes a waiter, counter correct;
uncontended mutex_lock takes no syscall (Lab 2 trace); join returns retval.

## 13. Hidden tests
Lost wakeup never lost across 1e5 iters; invalid futex addr → -1, no panic;
thread-group exit ends all threads; concurrent fork in a group handled per your
policy; fd sharing across siblings.

## 14. Performance measurement
Spinlock vs futex-mutex throughput and wasted-spin cycles at {1,2,4} harts;
futex syscall rate light vs heavy contention.

## 15. Required report (≤3 pages)
clone/thread-group model; futex atomicity (lost wakeup); exit policy; mutex/CV
fast path; contention measurement.

## 16. Viva questions
Show the lost-wakeup window in futex_wait and how the bucket lock closes it. What
does CLONE_VM share; what breaks if two threads sbrk at once? Defend your exit
policy vs Linux. Why does an uncontended mutex need no syscall?

## 17. Expected workload
~10h: 3h clone/join/tgid, 3h futex (atomicity crux), 2h libfutex, 1h measurement,
1h report.

## 18. Starter code provided
`kernel/futex.h`; clone hooks in proc.c; `user/libfutex.c` skeleton; `tests/lab06/`
lost-wakeup + sharing harnesses.

## 19. Staff-only reference requirements
Futex hash keyed by (pagetable,va); bucket-locked compare-and-sleep; tgid
teardown; libfutex CAS fast path; contention baselines.

## 20. Common incorrect approaches
Compare-then-sleep without holding the bucket lock across both (lost wakeup);
keying futexes by va only (cross-AS collisions); thread exit leaving siblings on
a freed AS; a fast path that always traps.

## 21. Suggested rubric (100)
clone/join/tgid 18 · thread-group exit 12 · futex atomicity 22 · libfutex 15 ·
contention 15 · viva 10 · report 8.

## 22. LLM-use declaration
Appendix. Futexes are documented; the viva "show the lost-wakeup window" and your
exit-policy defense are yours.

## 23. Anti-copying check
No public xv6 futex/clone lab; uthread is irrelevant. Lost-wakeup and AS-keyed
wait queues are the walls; the atomicity-window viva reveals understanding.
