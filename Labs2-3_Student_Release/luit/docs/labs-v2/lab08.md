# Lab 8 — Scalable Allocator & Lock Analysis

*CS3106L · Dr. Satyajit Das · IIT Guwahati · ~8 h take-home*

> **Not "add per-CPU freelists."** The per-CPU freelist is the known xv6 answer
> and earns no credit alone. This lab is measurement and comparison: instrument
> the baseline's contention, implement **at least two** allocator policies, and
> defend your choice with fairness and scaling *evidence*.

## 1. Educational objective
Diagnose lock contention quantitatively and evaluate competing scalability
policies with evidence, understanding throughput/fairness/complexity trade-offs.

## 2. Concepts covered
Lock contention and its measurement; per-hart caches; work stealing/batch
transfer; central reserves; fairness vs throughput; lock ordering; scaling.

## 3. Baseline components to read
`kernel/palloc.c` (single-lock free list — the bottleneck); Lab 2/Lab 3
(measurement instruments); Book Ch 6, Ch 9.

## 4. Warm-up task
Instrument the baseline: per-hart lock acquisitions and wait time for the palloc
lock, via an `alloc_stats` syscall. Run a multi-hart stress; report baseline
contention.

## 5. Main implementation tasks
**A** policy 1: per-hart cache with batch refill/return; tune batch size.
**B** policy 2 (distinct): central reserve w/ hysteresis, or work-stealing, or
hierarchical pools, or threshold redistribution — genuinely different from P1.
**C** instrumentation: per-hart counts, central-lock acquisitions, steals, and an
imbalance metric (max-min free). Preserve Lab 5 refcounts.
**D** invariants: `alloc_audit()` — pages conserved, no page on two lists, none lost.
**E** comparison: baseline/P1/P2 at {1,2,4} harts; throughput, contention,
imbalance; which you ship, defended with data.

## 6. Requirements that differ from xv6
Public = one policy. This needs two policies + contention instrumentation +
imbalance metric + conservation invariants + a data-driven comparison.

## 7. Required interfaces and system calls
`alloc_stats(struct allocstat*)`; `alloc_audit()`; a policy-select switch.

## 8. Required data structures
Per-hart cache + counters; central reserve; `struct allocstat`.

## 9. Concurrency and locking requirements
Per-hart locks (or none if strictly hart-local); central lock; a stated lock
order preventing deadlock; steal ordering by hart index (no ABBA); Lab 5
refcounts stay atomic.

## 10. Error-handling requirements
OOM returns 0 cleanly at every level; no partial-steal corruption; alloc_audit
never false-positives on a correct impl, always catches an injected leak.

## 11. Integration with previous labs
Preserves Lab 5 refcounts; uses Lab 2/Lab 3 for measurement; the instrumentation
is reused to measure Lab 11's journal overhead.

## 12. Public tests (`make grade LAB=8`)
Each policy passes alloc_audit after stress; multi-hart stress no deadlock at
CPUS=4; alloc_stats shows per-hart + central counts; COW (Lab 5) still passes.

## 13. Hidden tests
Conservation under 1e6 alloc/free × 4 harts; imbalance within a stated bound for
per-hart; steal-storm no deadlock/corruption; injected single-page leak caught;
refcount integrity under concurrent alloc/free.

## 14. Performance measurement
Throughput and central-lock contention vs hart count for baseline/P1/P2; the
imbalance metric per policy; the batch-size sweep for P1.

## 15. Required report (≤3 pages)
The two policies; lock order + deadlock argument; measurement tables/graphs;
which you ship and why; the fairness/throughput trade-off.

## 16. Viva questions
Where is the baseline's contention, and how measured? What does each policy
trade off? Show the lock order preventing a steal-storm deadlock. If per-hart is
faster, why not the largest batch?

## 17. Expected workload
~8h: 2h instrumentation, 3h two policies, 2h measurement, 1h report.

## 18. Starter code provided
`kernel/alloc_stats.h`; a policy-select scaffold in palloc.c; `tests/lab08/`
multi-hart stress + injected-leak harness; a measurement driver.

## 19. Staff-only reference requirements
Two reference policies with instrumentation; deadlock-free steal ordering;
baseline contention/throughput at 1/2/4 harts.

## 20. Common incorrect approaches
One policy only; a global lock retained inside the "per-hart" path (no win,
visible in data); unordered steal locks (deadlock); breaking refcounts.

## 21. Suggested rubric (100)
Instrumentation 15 · P1 15 · P2 15 · invariants 12 · comparison+analysis 25 ·
viva 10 · report 8. *(Analysis is 25%.)*

## 22. LLM-use declaration
Appendix. The per-CPU pattern is well-known; your comparison, imbalance metric,
and shipping decision are the graded originality.

## 23. Anti-copying check
Public = one policy, no measurement. Two policies + evidence + imbalance + audit
make copying insufficient; the "how did you measure contention" and "why not the
largest batch" viva need real data.
