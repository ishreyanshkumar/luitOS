# CS3106L Redesigned Lab Sequence (v2)

*Dr. Satyajit Das · Department of Computer Science and Engineering · IIT Guwahati*

These are the **redesigned** lab specifications, engineered so that students
cannot complete them by copying public xv6 solutions. Each lab has at least one
requirement no public xv6 solution satisfies. See each `labNN.md` for the full
24-section specification.

## The 12 labs and their anti-copying core

| # | Title | The requirement no public xv6 solution has | Built & verified |
|---|-------|---------------------------------------------|:---:|
| 1 | Systems comprehension & LUIT diagnostics | pstree/fdinfo/abimeta over LUIT's procstat + generated ABI | spec |
| 2 | Kernel tracing subsystem | per-hart rings, overflow accounting, measured overhead | **✅ code** |
| 3 | Versioned shared info page | seqlock consistency for a multiword snapshot | **✅ code** |
| 4 | User-level event delivery | nested-event prevention, malicious-handler hardening | spec |
| 5 | Advanced copy-on-write | refcount audit/invariants, copyout-COW, benchmark | **✅ code** |
| 6 | Kernel threads & futexes | futex lost-wakeup path + thread-group exit | spec |
| 7 | VirtIO-net & measured packet path | descriptor ownership, exhaustion accounting, loss-vs-load | spec |
| 8 | Scalable allocator & lock analysis | measured 2-policy comparison + imbalance metric | spec |
| 9 | LuitFS evolution | on-disk version bump + migration + fsck | spec |
| 10 | Integrated mmap | MAP_PRIVATE COW reusing Lab 5 + truncation | spec |
| 11 | Journalling & crash consistency (flagship) | 200-trial random crash campaign + invariant checker | spec |
| 12 | FDT/HAL portability (flagship) | boot same kernel on a pinned 2nd target, no core change | spec |

Labs 2, 3, and 5 have working, verified kernel implementations in this
repository (see kernel/trace.c, kernel/usysinfo.c, kernel/pgaudit.c + vm.c COW,
and tests/lab0{2,3,5}_*.sh). The remaining labs are fully specified; their
reference implementations are in progress.

## Longitudinal design (one coherent OS, not 12 exercises)

- Tracing (L2) → measurement tool for L5, L7, L8, L11
- Shared info page (L3) → surfaces stats for L5, L8, L11
- COW (L5) → reused by MAP_PRIVATE in L10
- Futexes (L6) → power the mutex/CV used by L10's pressure tests
- Allocator instrumentation (L8) → measures L7 and L11
- LuitFS versioning (L9) → carries the L11 journal's on-disk header
- HAL/FDT (L7, L12) → same abstraction exercised by device and silicon labs

## Contact hours: 32 (verified)

Double-labs weeks 1, 5, 9 (4h each); two-week take-home labs 5, 7; Viva 1 in
week 8. Full calendar in the course design document.
