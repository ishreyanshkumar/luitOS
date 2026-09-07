# Lab 1: util — Unix Utilities

*Weight: 4% of course grade · You will touch: user/ only*

**Goal.** Learn the system-call interface as a *user* of the OS before you ever change the kernel. Luit already boots to a shell with pipes and redirection; this lab is written inside it.

**Tasks.**
1. `sleep n` — pause for n ticks; print a usage error if the argument is missing.
2. `pingpong` — parent and child exchange one byte over a pair of pipes; each prints `<pid>: received ping/pong`.
3. `primes` — the concurrent prime sieve: a pipeline of processes, each filtering multiples of one prime, up to 280. Close descriptors you don't use — NOFILE is 16, deliberately, and the sieve exhausts it if you leak.
4. `find path name` — recursive directory walk (study `user/ls.c` for reading T_DIR inodes).
5. `xargs cmd` — read lines from stdin, run `cmd` with each line appended as arguments.

**What it teaches.** fork/exec/wait/pipe semantics, fd inheritance, pipe EOF, and why a reader that keeps its own write end open blocks forever.

**Viva seeds.** Why does `primes` deadlock if a filter keeps the upstream write end open? Exactly what does a child inherit across fork?

---

## Ground rules (all labs)

* Branch from `release/lab01`; `make grade LAB=1` must pass before submission; CI runs the same plus hidden tests.
* Your kernel must still pass **all baseline tests** — regressions cost marks even when the new feature works.
* The LLM policy for this lab is in `docs/LLM_POLICY.md`. Log every AMBER session as specified there.
