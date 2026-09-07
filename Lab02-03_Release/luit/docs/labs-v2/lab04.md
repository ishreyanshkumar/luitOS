# Lab 4 — User-Level Event Delivery

*CS3106L · Dr. Satyajit Das · IIT Guwahati · ~9 h take-home*

> **Beyond `sigalarm`.** The xv6 traps lab delivers a periodic callback. Ours
> builds a real user-level event-delivery mechanism: multiple sources, an
> alternate stack, masking, nested-delivery prevention, malicious-handler
> hardening, and measured delivery latency.

## 1. Educational objective
Understand trap entry/return deeply enough to redirect a user program to a
handler and back safely — even under a hostile handler — and measure the latency.

## 2. Concepts covered
Trapframes and saved state; privilege transitions; reentrancy/nesting; alt
stacks; masking; validating user handler addresses; latency via r_time().

## 3. Baseline components to read
`kernel/trap.c` (usertrap, timer arm, return); `kernel/defs.h` (struct trapframe);
`kernel/uservec.S`, userret; Lab 3's info page (events_pending field).

## 4. Warm-up task
Plain `sigalarm(interval,handler)`/`sigreturn()`. (The xv6 task — your foundation.)

## 5. Main implementation tasks
**A** two sources: timer event + a fault upcall (deliver a recoverable user
fault to a handler instead of killing).
**B** `event_stack(sp,size)` — handlers run on a separate stack.
**C** masking + nested prevention; `event_mask/unmask(classes)`.
**D** `event_return()` restores the FULL trapframe (all registers, epc, sp).
**E** malicious-handler protection: validate handler is mapped/user/exec at
register and delivery; a bad handler kills only the process.
**F** latency: cycles from condition-true to first handler instruction, and
from event_return to resumed code; distribution over ≥1000 deliveries.

## 6. Requirements that differ from xv6
Alt stack, masking, nested prevention, fault upcalls, address validation, full-
register-restore test, latency measurement — none in public sigalarm.

## 7. Required interfaces and system calls
`event_register(class,handler)`; `event_stack(sp,size)`; `event_mask/unmask`;
`event_return()`.

## 8. Required data structures
Per-process: handler table by class, saved trapframe copy, alt-stack descriptor,
mask word, in_handler depth.

## 9. Concurrency and locking requirements
Per-process bookkeeping guarded against timer delivery during setup (brief
interrupt-disable or careful ordering); in_handler/mask updated so a timer can't
nest a masked handler.

## 10. Error-handling requirements
Unmapped/non-user/non-exec handler → -1; event_return with none in flight → -1;
handler faulting on the alt stack → process dies, kernel survives; masked nested
delivery queued/coalesced, never re-entrant.

## 11. Integration with previous labs
Exposes events_pending in Lab 3's page. Fault upcall conceptually reused by Lab
10 (mmap recoverable faults). Uses Lab 2 tracing to record deliveries for latency.

## 12. Public tests (`make grade LAB=4`)
Timer handler runs after the interval and returns; handler runs on the alt stack;
masking blocks a second delivery; handler address 0/kernel → -1.

## 13. Hidden tests
Full-register restore after a clobbering handler; malicious loop killable;
corrupt return-address kills only the process; nested prevention under rapid
timers (correct coalesced count); alt-stack fault survivable; fault upcall runs
before exit.

## 14. Performance measurement
Latency distribution (min/median/p99) in cycles for delivery and return, ≥1000
events; with vs without the alt stack.

## 15. Required report (≤3 pages)
Masking/nesting policy; full save/restore vs partial; handler-validation
strategy; malicious-handler threat model; latency distribution.

## 16. Viva questions
Which registers must event_return restore, and what if you skip caller-saved?
How prevent a timer nesting a masked handler? How/when validate the handler
address? What stops a malicious handler escalating into the kernel?

## 17. Expected workload
~9h (term's hardest single-week): 3h save/restore + alt stack, 3h masking/
nesting/validation, 2h latency, 1h report.

## 18. Starter code provided
`kernel/event.h`; marked hooks in usertrap and the timer path; `user/evtest.c`;
`tests/lab04/` clobber-and-verify harness.

## 19. Staff-only reference requirements
Full trapframe copy; sp→alt stack; in_handler; handler validation via walkaddr +
PTE flags; malicious tests; latency baseline.

## 20. Common incorrect approaches
Restoring only epc/sp (fails clobber test — the common sigalarm shortcut); no
masking (nested crash); trusting the handler address (security hole); main stack
for the handler (alt-stack test fails).

## 21. Suggested rubric (100)
sigalarm 10 · full restore 20 · alt stack 12 · masking+nesting 18 · malicious
safety 15 · latency 12 · viva 13.

## 22. LLM-use declaration
Appendix. An LLM explains trapframes; it can't supply your masking policy or
survive the register-restore viva.

## 23. Anti-copying check
Public sigalarm = periodic delivery, often partial restore. The full-register
test, malicious tests, alt stack, and masking are outside its scope; the viva on
register restore and nesting exposes copied partial solutions.
