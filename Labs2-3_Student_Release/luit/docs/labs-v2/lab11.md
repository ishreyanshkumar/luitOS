# Lab 11 — Journalling & Crash Consistency (Flagship)

*CS3106L · Dr. Satyajit Das · IIT Guwahati · flagship · ~12 h take-home*

> **The lab xv6 students never do.** xv6 *ships* its log; students only read it.
> LuitFS deliberately has none — you build a **write-ahead log**, prove it with
> **deterministic and random crash campaigns**, verify invariants, measure
> overhead, and analyze one **failed design**. This is the crash-consistency
> flagship and one of the four indigenous obligations made real.

## 1. Educational objective
Make LuitFS crash-consistent via a write-ahead journal, and *prove* it survives
power loss at arbitrary points — turning "survives crashes" from a claim into a
demonstrated property.

## 2. Concepts covered
Atomicity of multi-block operations; write-ahead logging; commit records;
recovery/replay on mount; crash injection; invariant checking; the cost of
durability; ordering and barriers to disk.

## 3. Baseline components to read
`kernel/fs.c` (the multi-block ops that must become atomic: create, unlink,
link, writei growth, Lab 9's rename); `kernel/bio.c` (the buffer cache); Lab 9
(versioning/mount path the log header reuses); Book Ch 8 §8.9.

## 4. Warm-up task
Wrap `create` in begin_op/end_op that log modified blocks to a reserved region
and install on commit. Demonstrate the log filling and draining.

## 5. Main implementation tasks
**A** the write-ahead log: reserved region (superblock's nlog via Lab 9). Every
mutation: begin_op → writes to log → end_op writes a **commit record** → logged
blocks copied to real homes → log cleared. Crash before commit = untouched;
after = replayed.
**B** recovery on mount: scan the log; replay committed, discard uncommitted;
consistent regardless of crash timing.
**C** transaction batching + ordering: group commit or serialize (documented).
The ordering — log fully synced before the commit record, commit synced before
installation — is the heart of correctness; enforce with explicit disk ordering.
**D** invariant checker `fsinvariants()` (or reuse Lab 9 fsck): after crash+
recovery, no block both free and referenced; link counts consistent; no orphans;
tree connected; Lab 9 checksums valid.
**E** crash campaigns: **deterministic** (crash at each labeled point in create/
unlink/rename → remount, recover, check — all pass); **random** (harness kills
the emulator at randomized instants during a metadata storm — **≥200 trials must
leave the fs consistent**).
**F** overhead + a failed design: measure throughput/write-amplification vs the
no-journal baseline (Lab 8 framework); document one wrong design you tried (e.g.
install-before-commit or a missing sync barrier) and how a campaign exposed it.

## 6. Requirements that differ from xv6
Everything — students never build the log. Beyond even xv6's shipped log: deter-
ministic + random campaigns, an invariant checker, overhead, failed-design analysis.

## 7. Required interfaces and system calls
begin_op()/end_op() (internal); fsinvariants()/fsck for campaigns; a crash-
injection hook (`crashpoint(int id)` or probability-driven abort) driven by the harness.

## 8. Required data structures
On-disk: log header (magic, version, block count, commit flag), log slots
(versioned via Lab 9); in-memory: current transaction's block list, log state.

## 9. Concurrency and locking requirements
begin_op/end_op coordinate concurrent ops (group into one transaction with a
commit barrier, or serialize; documented/enforced); the log lock; the commit
sequence is a critical ordering, not just a critical section — disk writes
ordered even across the buffer cache.

## 10. Error-handling requirements
A crash at any point leaves a recoverable state; log overflow prevented by
bounding op size or splitting (documented); a corrupt log header (Lab 9 checksum)
detected, recovery refuses to replay garbage.

## 11. Integration with previous labs
Rides on **Lab 9's versioning** (adds a format version, reuses mount validation)
and **Lab 9's fsck/checksums** (the invariant checker); uses **Lab 8's framework**
for overhead; makes the persistence property Book Ch 8 describes actually true.

## 12. Public tests (`make grade LAB=11`)
A create survives crash-before-commit (file absent) and crash-after-commit (file
present); recovery replays committed / discards uncommitted; fsinvariants passes
clean; overhead measured (nonzero, bounded).

## 13. Hidden tests
Deterministic campaign: crash at each labeled point → every remount consistent;
random campaign: ≥200 randomized instants → 100% consistent; an install-before-
commit build fails the campaign; log overflow bounded/split, not corrupting; a
garbage log header not replayed.

## 14. Performance measurement
Throughput and write-amplification with vs without the journal (Lab 8 framework);
recovery time vs log size; the group-commit effect if implemented.

## 15. Required report (≤4 pages — this flagship allows more)
The log format + commit protocol; the ordering rule and how you enforce it to
disk; the recovery algorithm; deterministic + random campaign results (pass
rates); overhead numbers; the **failed design** and how a campaign caught it.

## 16. Viva questions
State the exact write ordering that makes a transaction atomic across a crash.
What does recovery do for committed vs uncommitted? How does a crash after the
commit record but before installation recover? Describe the failed design and
the crash that exposed it.

## 17. Expected workload
~12h: 3h log+commit, 3h recovery, 3h crash harness+campaigns, 2h overhead/failed-
design, 1h report.

## 18. Starter code provided
`kernel/log.h`; begin_op/end_op hooks around FS mutations; the crash-injection
harness `tests/lab11/` (deterministic points + random killer); fsinvariants
skeleton (or Lab 9 fsck reuse).

## 19. Staff-only reference requirements
WAL with correct ordering + group commit; recovery; a ≥200-trial random campaign
that passes; overhead baselines; a deliberately-mis-ordered variant for the
"ordering violation caught" demo.

## 20. Common incorrect approaches
Installing logged blocks before the commit record (the canonical bug); a missing
sync barrier so the disk reorders commit vs data; replaying a log without
validating its header; unbounded transactions overflowing the log.

## 21. Suggested rubric (100)
log+commit 18 · recovery 18 · deterministic campaign 15 · random campaign (≥200)
20 · overhead 10 · failed-design analysis 9 · viva 10.

## 22. LLM-use declaration
Appendix. WAL is a described pattern; learn it via LLM. The ordering enforcement
to disk, the campaign results, and your failed-design analysis are your own — and
the "state the exact ordering" / "the failed design" viva are where copied logs collapse.

## 23. Anti-copying check
No public xv6 build-the-log lab. The random crash campaign (≥200 non-deterministic
trials) cannot be copied — it passes on a correct implementation or exposes the
bug. The failed-design requirement and the ordering viva require genuine work.
