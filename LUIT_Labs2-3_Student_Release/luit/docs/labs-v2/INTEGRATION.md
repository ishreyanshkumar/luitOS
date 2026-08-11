# CS3106L Lab Sequence — Integration & Gap Report (Stage 7)

*Dr. Satyajit Das · Department of Computer Science and Engineering · IIT Guwahati*

This document ties the redesigned laboratory sequence together: the dependency
graph, the migration from the old sequence, and an honest breakdown of completed
vs. pending work with release gates.

## 1. Dependency graph

Labs are not independent; later labs consume infrastructure built earlier. An
arrow A → B means "B reuses or measures with A".

    L1 diagnostics ─┬─> L2 (uses ppid/fdstat)
                    └─> L3 (uses per-proc counters exposed via the page)

    L2 tracing ─────┬─> L5  (counts COW faults)
                    ├─> L7  (records packet-path events)
                    ├─> L8  (measures lock contention)
                    └─> L11 (measures journal overhead)

    L3 shared page ─┬─> L5  (surfaces refcount/COW stats)
                    ├─> L8  (surfaces allocator stats)
                    └─> L11 (surfaces journal state)

    L5 COW ─────────> L10 (MAP_PRIVATE reuses the refcount + fault machinery)

    L6 futexes ─────> L10 (the mutex/CV drive the threaded pressure tests)

    L8 allocator ───┬─> L7  (measurement framework)
      instrumentation└─> L11 (measurement framework)

    L9 LuitFS v2 ───> L11 (the journal rides on the on-disk versioning + fsck)

    L7 HAL/FDT ─────> L12 (same abstraction; the portability flagship)

    (everything) ───> L12 (the same kernel must boot unchanged on a 2nd target)

Consequences for scheduling: L1–L3 must come first (they are infrastructure);
L5 before L10; L6 before L10; L9 before L11; L7 before/with L12. The calendar in
the course-design document already respects this ordering.

## 2. Migration from the old 12-lab sequence

| Old lab | Fate in the redesign |
|---------|----------------------|
| util | folded into L1 as a 2-program warm-up; the bulk is now LUIT diagnostics |
| syscall (trace/sysinfo) | replaced by L2 (tracing subsystem) |
| pgtbl (USYSCALL/vmprint) | replaced by L3 (seqlock shared page) |
| traps (sigalarm) | extended into L4 (user-level event delivery) |
| cow | retained + extended as L5 (audit, benchmark, invariants) |
| thread (uthread) | replaced by L6 (clone + futexes) |
| net | hardened into L7 (VirtIO-net + measured packet path) |
| lock | reframed as L8 (policy comparison + measurement) |
| fs | replaced by L9 (versioning + migration + fsck) |
| mmap | extended into L10 (integrated, reuses L5/L6/L9) |
| crash | kept as L11 flagship (+ campaigns, invariant checker) |
| silicon | kept as L12 flagship (+ pinned target, RAM-fs fallback) |

No student-facing artefact from the old sequence is carried forward unchanged;
every high-overlap lab gained a requirement no public xv6 solution satisfies.

## 3. Completed work (verified)

- Stage 1 (audit), Stage 2 (sequence, 32 contact hours), Stage 3 (all 12 full
  student specs) — complete.
- Kernel code BUILT, BOOTED, TESTED, baseline 9/9 preserved:
  - L1 diagnostics (pstree/fdinfo/syscalls + ppid/fdstat/abimeta syscalls)
  - L2 tracing (per-hart rings, overflow accounting, fork inheritance)
  - L3 seqlock shared info page (20000 snapshots torn=0, no leak)
  - L5 copy-on-write (lazy fork 7/64, copyout-COW, pgaudit, sfence fix)
  - L6 kernel threads + futexes (clone shares AS, futex mutex, counter=6000/4 harts)
- Infrastructure: `make grade LAB=N` harness; per-lab public tests for L1/2/3/5/6;
  release/staff branch structure; release-engineering guide.

## 4. Partially completed

- Staff references exist (`staff/reference/`) for L2/L3/L5/L6; formal per-lab
  staff spec documents (Stage 4) are not yet written for any lab.
- Branches `release/labNN` and `staff/solution-labNN` exist as markers but are
  not yet populated with per-lab skeleton/solution trees.

## 5. Unimplemented

- Kernel code for L4, L7, L8, L9, L10, L11, L12 (specs complete; code pending).
  The flagships L11 (journalling + crash harness) and L12 (sifive_u HAL bring-up)
  are the largest remaining efforts.
- Hidden-test suites (as opposed to the public tests that exist).
- The `tests/labNN/` starter harness directories referenced in specs for the
  unbuilt labs.

## 6. Hardware-dependent work

- L12's optional physical SHAKTI/VEGA bring-up is bonus and cannot be verified in
  this environment; the pinned QEMU `sifive_u` target is the gradeable path and
  is itself still to be implemented.
- L7's VirtIO-net requires QEMU netdev configuration; the driver is unbuilt.

## 7. Risks before semester deployment

1. **Unbuilt flagships (L11, L12).** Highest risk: they are the course's
   signature labs and the largest. Mitigation: build and verify both against
   QEMU well before week 14; treat L11's ≥200-trial random crash campaign as the
   acceptance gate.
2. **Staff solutions not yet complete for 7 labs.** Grading cannot be finalised
   until reference implementations exist. Mitigation: build reference code lab-by-
   lab (as done for L1/2/3/5/6), each verified before the lab is released.
3. **Student/staff separation.** Solutions live on `master` and `staff/*`; a
   student release MUST be an orphan commit (see docs/RELEASE.md) or solutions
   leak through history.
4. **Environment reproducibility.** The toolchain (gcc-riscv64-unknown-elf) and
   QEMU must be pinned; a Docker image is recommended so graders and students
   share exact versions.

## 8. Recommended release gates (per lab)

Before releasing lab N to students:
- [ ] `git status --porcelain` empty before and after `make clean && make -j`
- [ ] baseline `make grade` = 9/9 (no regression from the lab's baseline changes)
- [ ] `make grade LAB=N` public checks pass
- [ ] reference solution on `staff/solution-labN` passes both public and hidden tests
- [ ] student release built as an orphan commit with no solution reachable
- [ ] handout `docs/labs-v2/labN.md` reviewed for the four indigenous obligations
      where relevant (boot on real silicon, FDT discovery, crash consistency,
      versioned ABI)

## 9. Bottom line

The intellectual design (Stages 1–3) is complete and durable. Five of twelve
labs have verified, running kernel implementations with tests. The remaining
seven are fully specified and await implementation, with the two flagships as the
critical path. Nothing is claimed as tested that has not actually been built and
run; this report is the honest gap picture as of this snapshot.
