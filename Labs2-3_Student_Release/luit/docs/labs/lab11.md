# Lab 11: crash — Journalling & Crash Consistency

*Weight: 5% of course grade · You will touch: kernel/fs.c (log layer), tests/crash/*

**Goal.** Make LuitFS crash-consistent. This is the lab xv6 students never get — xv6 ships with its log already written; you will write ours. The superblock's reserved `nlog` field has held this seat since version 1.

**Tasks.**
1. A write-ahead intent log: wrap every multi-block operation in begin_op/end_op; committed operations replay on mount, uncommitted ones vanish atomically.
2. Recovery in `fsinit`: scan, replay or discard, then run. LUITFS_VERSION bumps to 3.
3. Crash injection: the harness SIGKILLs QEMU at randomized points during a create/write/unlink storm, remounts, and audits invariants (no orphaned or double-allocated blocks, connected directory tree). **Survive ≥200 randomized trials.** Hidden grading uses different seeds and kill-point distributions.

**Why it matters here.** "Crash-consistent storage surviving power loss" is one of this course's four non-negotiable claims about the system. After this lab, it is true because *you* made it true.

**Viva seeds.** Why log whole blocks rather than byte diffs? What bounds the size of one operation, and what enforces the bound?

---

## Ground rules (all labs)

* Branch from `release/lab11`; `make grade LAB=11` must pass before submission; CI runs the same plus hidden tests.
* Your kernel must still pass **all baseline tests** — regressions cost marks even when the new feature works.
* The LLM policy for this lab is in `docs/LLM_POLICY.md`. Log every AMBER session as specified there.
