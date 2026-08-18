# Lab 6: thread — Multithreading

*Weight: 3% of course grade · You will touch: user/uthread.c + host-side pthread exercises*

**Goal.** Switching between threads — first by building it, then by using the real thing.

**Tasks.**
1. *uthread:* cooperative user-level threads over a pool of stacks; write `uthread_switch.S` saving exactly the callee-saved registers (mirror `kernel/swtch.S`, and be ready to say why caller-saved ones need no saving).
2. *ph (host Linux, real pthreads):* a hash table loses keys under two threads — find the races, fix them with mutexes, then make it scale (per-bucket locks).
3. *barrier (host Linux):* implement a reusable barrier with a condition variable; rounds must not interleave.

**Challenge (optional, +2%).** An MLFQ scheduler in the kernel: three queues, demotion on slice exhaustion, periodic boost. `procstat()` is your observability hook.

**Viva seeds.** Why doesn't a context switch save `t0`? In ph, why does a lock per bucket scale where one lock doesn't — and what stops scaling next?

---

## Ground rules (all labs)

* Branch from `release/lab06`; `make grade LAB=6` must pass before submission; CI runs the same plus hidden tests.
* Your kernel must still pass **all baseline tests** — regressions cost marks even when the new feature works.
* The LLM policy for this lab is in `docs/LLM_POLICY.md`. Log every AMBER session as specified there.
