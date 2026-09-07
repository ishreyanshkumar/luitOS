# Lab 2: syscall — System Calls

*Weight: 4% of course grade · You will touch: kernel/syscall.tbl, kernel/syscall.c, kernel/proc.**

**Goal.** Add your first system calls end-to-end: table row → kernel handler → generated user stub → user program.

**Tasks.**
1. `trace(mask)` — per-process syscall tracing, inherited by children. Each traced syscall prints one line at return: `pid: syscall name -> retval`. Hook the single dispatch point in `syscall()` — the generated `syscall_name()` helper is already waiting there for you.
2. `sysinfo(struct sysinfo *)` — fill `{freemem, nproc}` via `copyout`. Free memory comes from the page allocator; `nproc` counts non-UNUSED slots.
3. Both go into `kernel/syscall.tbl`. Never hand-edit generated files — the build regenerates them, and a "generated files clean" check is graded.

**Viva seeds.** Why must sysinfo use copyout rather than writing through the user pointer? Where does the trace mask live, and why must fork copy it?

---

## Ground rules (all labs)

* Branch from `release/lab02`; `make grade LAB=2` must pass before submission; CI runs the same plus hidden tests.
* Your kernel must still pass **all baseline tests** — regressions cost marks even when the new feature works.
* The LLM policy for this lab is in `docs/LLM_POLICY.md`. Log every AMBER session as specified there.
