# Lab 2 — Kernel Tracing Subsystem

*CS3106L · Dr. Satyajit Das · IIT Guwahati · ~8 h take-home*  **[REFERENCE CODE VERIFIED]**

> **Beyond `trace(mask)`.** The xv6 trace lab prints a line per syscall — a
> five-line change with a public solution. Ours builds a **kernel-resident
> tracing subsystem**: per-hart ring buffers, timestamps, overflow accounting,
> fork-inheritance, streaming retrieval, and *measured* overhead.

## 1. Educational objective
Build a concurrency-safe, low-overhead in-kernel event tracer and reason
quantitatively about the cost of observability.

## 2. Concepts covered
Per-hart data; ring buffers; timestamps (r_time()); the single dispatch
chokepoint; fork inheritance of kernel state; kernel→user streaming; overhead.

## 3. Baseline components to read
`kernel/syscall.c` (dispatch); `kernel/proc.c` (mycpu, per-hart); `kernel/riscv.h`
(r_time); Lab 1's abimeta (syscall names).

## 4. Warm-up task
Minimal `trace(mask)` printing one line per traced syscall — only to find the
dispatch point. Worth little; you replace it with the ring.

## 5. Main implementation tasks
**A** per-hart ring of `struct trace_event {pid,hart,num,ts,ret,arg0}`.
**B** collect at dispatch after the handler returns, filtered, preemption-safe.
**C** overflow → per-ring `dropped` counter (never silent, never block).
**D** `tracectl(action,filter)`; fork inherits the filter.
**E** `traceread(buf,max)` drains all harts in ~timestamp order; `user/trace.c`.
**F** measure overhead: off vs ring vs naive printf, on a fixed workload.

## 6. Requirements that differ from xv6
Per-hart rings, overflow accounting, structured timestamped events, cross-hart
drain, measured overhead — none in the public single-mask `trace`.

## 7. Required interfaces and system calls
`tracectl(int action,int filter)`; `traceread(struct trace_event*,int)`.

## 8. Required data structures
`struct trace_event{int pid,hart,num; uint64 ts; long ret; uint64 arg0;}`;
per-hart `struct trace_ring{ev[NTRACE],head,tail,dropped,lock}`; per-proc filter.

## 9. Concurrency and locking requirements
Hot path takes no global lock (per-ring lock or documented lock-free SP ring).
traceread synchronizes with producers (per-ring lock or seqlock on head/tail).
Fork copies settings under the child's lock.

## 10. Error-handling requirements
traceread max<=0 → -1; partial drains return what fit; overflow never corrupts;
dropped is monotonic until read; a traced process exiting loses no recorded events.

## 11. Integration with previous labs
Reuses Lab 1 abimeta for names. The tracer is reused as the measurement tool in
Labs 5, 7, 8, 11.

## 12. Public tests (`make grade LAB=2`)
`trace ls` yields open/read/close events; every hart field valid; timestamps
non-decreasing per hart; a child of a traced process is traced (inheritance).

## 13. Hidden tests
Overflow → exact dropped count; two harts, no torn event; file-only filter
excludes getpid/uptime; ordered drain across two traceread calls; disable
mid-run records nothing after.

## 14. Performance measurement
Table: ticks under {off,ring,printf}; events/s; bytes/event; per-syscall ring
overhead in cycles.

## 15. Required report (≤3 pages)
Ring design + concurrency argument; inheritance; overhead table; a race hit/
avoided; why per-hart beats a global ring.

## 16. Viva questions
Why per-hart? What does it cost traceread? Show the torn-event window and your
prevention. What does fork copy for trace settings, and when? Why is buffered
tracing cheaper than printf — in cycles?

## 17. Expected workload
~8h: 2h ring+dispatch, 3h filter/inheritance/drain, 2h measurement, 1h report.

## 18. Starter code provided
`kernel/trace.h`; a marked hook in syscall.c; `user/trace.c` skeleton;
`tests/lab02/` workload generator.

## 19. Staff-only reference requirements
Per-hart ring + per-ring spinlock; traceread merges by timestamp; a lock-free
variant for bonus; reference overhead numbers.

## 20. Common incorrect approaches
One global ring+lock (fails the contention intent, visible in overhead); silent
overflow (fails dropped-count test); unsynchronized head/tail in traceread
(torn-read); recording before the handler returns (wrong retval).

## 21. Suggested rubric (100)
Ring+dispatch 20 · overflow 12 · filter+inheritance 18 · drain ordering 15 ·
overhead 15 · report 12 · viva 8.

## 22. LLM-use declaration
Appendix. Ring-buffer concepts via LLM are fine; a generated traceread whose
synchronization you can't defend fails.

## 23. Anti-copying check
Closest public = trace(mask): none of per-hart rings, overflow accounting,
structured events, cross-hart drain, or overhead data. Hidden overflow/torn tests
+ the "show the torn-event window" viva require real understanding.

---
*Reference implementation in this repo: `kernel/trace.{c,h}`, `user/trace.c`,
`tests/lab02_trace.sh`. Verified: 129 events on `trace ls`, fork inheritance,
overflow count 908, baseline 9/9.*
