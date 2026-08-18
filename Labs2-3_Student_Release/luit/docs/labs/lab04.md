# Lab 4: traps — Traps

*Weight: 5% of course grade · You will touch: kernel/trap.c, kernel/proc.*, kernel/printf.c*

**Goal.** Understand trapframes well enough to re-enter user space somewhere new.

**Tasks.**
1. *RISC-V assembly warm-up:* answer the worksheet on `user/call.asm` (which registers hold arguments? where does the compiler put a constant call?).
2. *backtrace():* walk saved frame pointers up the kernel stack printing return addresses; wire it into `panic()` so every future crash self-describes.
3. *sigalarm/sigreturn:* after every `interval` ticks of a process's own CPU time, force it into `handler`; `sigreturn` restores the interrupted state exactly. Save the FULL trapframe — restoring only `epc` and `sp` passes the easy test and fails the hidden register-preservation one.

**Viva seeds.** What exactly must sigreturn restore, and what goes wrong if `a0` is skipped? Why must the handler not be re-entered while one is running?

---

## Ground rules (all labs)

* Branch from `release/lab04`; `make grade LAB=4` must pass before submission; CI runs the same plus hidden tests.
* Your kernel must still pass **all baseline tests** — regressions cost marks even when the new feature works.
* The LLM policy for this lab is in `docs/LLM_POLICY.md`. Log every AMBER session as specified there.
