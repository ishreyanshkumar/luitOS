# Lab 5 — Advanced Copy-on-Write Memory

*CS3106L · Dr. Satyajit Das · IIT Guwahati · TWO-WEEK · double-lab · ~12 h*  **[REFERENCE CODE VERIFIED]**

> **COW is the foundation, not the whole lab.** We keep copy-on-write fork as
> the base, then add what no public solution has: a shared zero page, a refcount
> auditing/invariant interface, a leak detector, correct copyout under COW, and
> a quantitative eager-vs-COW benchmark. Grade rests on evidence and invariants.

## 1. Educational objective
Implement COW fork correctly AND prove it: no leaks, no double-frees, balanced
refcounts, with instrumentation and benchmarks.

## 2. Concepts covered
Page refcounting; the write-fault path; PTE_COW; shared zero page; copyout/kernel
writes to COW pages; invariants/leak detection; fork/exec economics; measurement.

## 3. Baseline components to read
`kernel/palloc.c` (refcount array, dormant); `kernel/vm.c` (uvmcopy, copyout,
mappages); `kernel/trap.c` (fault hook); `kernel/riscv.h` (PTE_COW); Labs 2, 3.

## 4. Warm-up task
Convert eager uvmcopy to COW: map parent pages RO+PTE_COW into the child, bump
refcounts, copy nothing; resolve write faults by copy-or-reclaim.

## 5. Main implementation tasks
**A** global shared zero page for fresh anonymous/BSS pages until first write.
**B** `pgrefstat(va)` + `pgaudit()` invariant checker.
**C** correct copyout under COW (kernel writes copy first).
**D** leak detector: net-zero pages after a fork/exec/exit storm.
**E** memory-pressure: a COW fault that can't allocate fails gracefully.
**F** benchmark eager vs COW: fork+exec latency and peak pages, child sizes
{small,1MB,16MB}; report the crossover.

## 6. Requirements that differ from xv6
Shared zero page, pgaudit invariants, pgrefstat, leak detector, graceful
pressure, and the benchmark — all outside the public "write fault copies" COW.

## 7. Required interfaces and system calls
`pgrefstat(va,struct pgref*)`; `pgaudit()`; COW stats via Lab 3 page.

## 8. Required data structures
`struct pgref{int refcount,cow,is_zero;}`; the palloc refcount array (made live);
per-boot leak counters.

## 9. Concurrency and locking requirements
Refcount inc/dec atomic across harts; the fault handler's check-and-copy is a
critical section (two harts faulting one page → exactly one copies); the zero
page's refcount never reaches 0.

## 10. Error-handling requirements
COW fault OOM → kill faulting process, survive; pgrefstat on unmapped → -1;
pgaudit returns the first-violated invariant; double-free/underflow panic in debug.

## 11. Integration with previous labs
Uses Lab 2 (COW fault counts), exposes stats via Lab 3. **Lab 10's MAP_PRIVATE
reuses this COW machinery directly.**

## 12. Public tests (`make grade LAB=5`)
Child writes don't affect parent; fork of a 4MB proc copies 0 pages until write;
pgaudit==0 after a clean fork/exit; BSS/sbrk share the zero page until written.

## 13. Hidden tests
copyout-under-COW copies correctly, parent untouched; 100 fork/exec/exit →
pgaudit==0; two-hart same-page write → one copy, balanced refcounts; at -m 8M a
fork-bomb-lite fails cleanly; zero page never freed/written.

## 14. Performance measurement
fork+exec latency and peak RSS eager vs COW × three sizes; COW-fault counts (Lab
2); zero-page savings.

## 15. Required report (≤3 pages)
Refcount atomicity; the copyout-COW fix; the invariant set and why sufficient;
the benchmark with analysis; pressure behaviour.

## 16. Viva questions
Why must copyout trigger COW? Show the bug if not. Two harts fault one page —
guarantee a single copy. Which invariant catches a leak? When does COW not help?

## 17. Expected workload
~12h/two weeks: 3h core, 3h zero page + atomicity, 3h audit/leak/pressure, 2h
benchmark, 1h report.

## 18. Starter code provided
Marked COW hook in trap.c; `kernel/pgaudit.h`; `tests/lab05/` leak+pressure;
`user/forkbench.c`.

## 19. Staff-only reference requirements
Atomic refcounts; single-copy fault; saturating zero-page refcount; full pgaudit;
benchmark baselines.

## 20. Common incorrect approaches
copyout writing the shared page; non-atomic refcounts (double-copy/leak);
freeing the zero page; no graceful pressure handling; **missing sfence_vma() in
the fault handler — a stale RO TLB entry corrupts memory far from the fault (the
symptom is a shell pipeline running the wrong command).**

## 21. Suggested rubric (100)
COW core 15 · zero page 12 · atomicity 12 · pgaudit 15 · copyout-COW 10 ·
leak+pressure 12 · benchmark 14 · viva 10.

## 22. LLM-use declaration
Appendix. The COW core is heavily documented; declare use. Invariants, benchmark,
and the copyout fix are where your understanding must show.

## 23. Anti-copying check
Public COW = write-fault copy: no zero page, pgaudit, leak detector, copyout-COW
test, or benchmark. The viva "show the copyout bug" and "guarantee single copy"
defeat copied cores.

---
*Reference in this repo: COW in `kernel/vm.c` (uvmcopy+cowfault), `kernel/pgaudit.c`,
`tests/lab05_cow.sh`. Verified: fork of 64-page proc copies 7 pages (lazy),
isolation, copyout-COW, pgaudit=0, 1 and 4 harts, baseline 9/9. The critical
sfence_vma() in cowfault is required or the shell pipe corrupts.*
