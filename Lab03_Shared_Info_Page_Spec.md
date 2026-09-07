# Lab 3 — Versioned Shared Kernel–User Info Page

*CS3106L · Dr. Satyajit Das · IIT Guwahati · ~7 h take-home*  **[REFERENCE CODE VERIFIED]**

> **Beyond `USYSCALL`.** The xv6 pgtbl lab maps a page holding one integer.
> Ours maps a **multi-field, versioned** page and confronts the problem a single
> int never poses: consistent multiword reads while the kernel updates — solved
> with a **seqlock**.

## 1. Educational objective
Design a lock-free, consistent, read-mostly kernel↔user protocol (a seqlock) and
build fast user accessors that avoid syscalls yet never see a torn snapshot.

## 2. Concepts covered
Kernel/user shared pages via the page table; read-mostly synchronization;
seqlocks; memory ordering/barriers; syscall vs shared-read cost; versioning.

## 3. Baseline components to read
`kernel/vm.c` (mappages, permissions); `kernel/proc.c` (per-process page setup);
`kernel/riscv.h` (PTE_R/PTE_U, barriers); Lab 2's per-process counters.

## 4. Warm-up task
Map a read-only page with just the pid; reimplement getpid() in user space with
no trap. (This is the xv6 task — your scaffold.)

## 5. Main implementation tasks
**A** `struct usysinfo {version,seq,pid,ppid,hart,ticks,syscall_count,ctxsw_count,state_gen}` mapped read-only at a fixed VA.
**B** the seqlock: writer `seq++`(odd)→barrier→write fields→barrier→`seq++`(even);
reader reads seq (retry if odd)→barrier→read→barrier→re-read seq, retry if changed.
**C** fast accessors `u_getpid/u_uptime/u_snapshot` — pure page reads.
**D** measure syscall vs page read (1e6 iters); prove no torn snapshot under a
hart hammering updates.

## 6. Requirements that differ from xv6
Seqlock, multiword consistency, versioned layout, torn-snapshot test — none in
the single-int USYSCALL.

## 7. Required interfaces and system calls
No new syscall on the fast path (the point). Optional `usysinfo_addr()` helper.

## 8. Required data structures
`struct usysinfo` (fields above); per-process pointer in struct proc.

## 9. Concurrency and locking requirements
Writer runs in kernel context (timer/dispatch/scheduler) with odd/even + correct
barriers. Page is read-only in user space (write faults, no kernel corruption).
Argue single-writer-per-process (a process runs on one hart at a time).

## 10. Error-handling requirements
Older-version reader detects mismatch, falls back to syscall. A write to the RO
page faults the user process only.

## 11. Integration with previous labs
Exposes Lab 2's syscall_count. ctxsw_count/state_gen consumed by Labs 5, 8 as a
zero-syscall counter read.

## 12. Public tests (`make grade LAB=3`)
u_getpid==getpid; u_uptime tracks uptime within a tick; a user write to the page
kills the writer not the kernel; version matches.

## 13. Hidden tests
Torn-snapshot stress (1e6 snapshots, invariants never violated); seq even when
idle; u_snapshot terminates under continuous updates; two processes see different
pages.

## 14. Performance measurement
ns/op getpid vs u_getpid; speedup; u_snapshot retry rate under light vs heavy load.

## 15. Required report (≤2 pages)
The seqlock with barrier placement justified; why odd=in-progress; torn-snapshot
argument; the measurement; the retry-rate observation.

## 16. Viva questions
Why does even/odd guarantee consistency? Where do the two barriers go, and what
breaks if you drop the second? Why can a reader spin-retry but a writer must not?
Why read-only?

## 17. Expected workload
~7h: 1h mapping, 3h seqlock (barriers are the hard part), 2h measurement, 1h report.

## 18. Starter code provided
`kernel/usysinfo.h` with struct+version; a marked mapping hook in allocproc;
`user/ulibfast.c` skeleton; `tests/lab03/` torn-snapshot harness.

## 19. Staff-only reference requirements
Correct __atomic release/acquire seqlock; writer hooks in timer, dispatch, swtch;
a deliberately-broken "missing barrier" variant.

## 20. Common incorrect approaches
Writing fields without the odd/even bracket; dropping the barrier before the
final seq++ (reorders under -O); writable page; a global shared page.

## 21. Suggested rubric (100)
getpid warm-up 8 · mapping 15 · seqlock correctness 30 · fast accessors 12 ·
torn-snapshot survival 15 · measurement 12 · viva 8.

## 22. LLM-use declaration
Appendix. Seqlocks are a named pattern; learn it via LLM, but the viva asks you
to place and justify the barriers.

## 23. Anti-copying check
USYSCALL = one int, no consistency, no seqlock/version/torn test. The multiword-
consistency requirement is the wall; the "drop the second barrier" viva reveals depth.

---
*Reference in this repo: `kernel/usysinfo.{c,h}`, reader in `user/ulib.c`,
`tests/lab03_usysinfo.sh`. Verified: 20000 snapshots torn=0, RO write faults,
no page leak, baseline 9/9. (A one-page-per-proc leak was found and fixed —
uvmfree skips VAs above sz; the info page is freed explicitly in freeproc.)*
