# CS3106L Course Operations — v1.0
*Dr. Satyajit Das · Department of Computer Science and Engineering · IIT Guwahati*
*(Companion to the course design document; the operational single-pager set.)*

## 1. 14-week calendar (3-0-2-8: 42 h theory, 32 h lab)

Twelve labs, sequenced on the MIT 6.S081 spine (util → syscall → pgtbl → traps → cow → thread → net → lock → fs → mmap) plus the two labs that carry Luit's indigenous obligations (crash, silicon). Lab slots are 2 h; **double-lab weeks (4 h): 1, 12, 13**; vivas replace lab contact in weeks 8 and 14.

| Wk | Theory (3 h) | Lab | Due |
|----|--------------|-----|-----|
| 1 | OS roles; processes & the syscall model; a guided tour of Luit; C+GDB clinic | **(double)** Lab 1 util | — |
| 2 | OS organization; kernel entry/exit | Lab 2 syscall | L1 |
| 3 | Virtual memory I: Sv39, walks, TLB; Luit's no-trampoline design | Lab 3 pgtbl | L2 |
| 4 | Traps and interrupts; trapframes; timers | Lab 4 traps | L3 |
| 5 | Page faults as a feature; the economics of fork | Lab 5 cow (assigned; 2 weeks) | L4 |
| 6 | Locking; the lost wakeup; sleep/wakeup | Lab 5 cow continues | — |
| 7 | Scheduling: mechanism (swtch) and policy (MLFQ/CFS sketch) | Lab 6 thread | L5 |
| 8 | Q&A + exam-style problem session | **VIVA 1** (labs 1–5, 15 min/student) | L6 |
| 9 | Device drivers; virtio; DMA and memory barriers | Lab 7 net (assigned; 2 weeks) | — |
| 10 | Interrupt handling at depth; receive livelock | Lab 7 net continues | — |
| 11 | Multi-core scalability; measuring contention | Lab 8 lock | L7 |
| 12 | File systems: inodes, directories, caches | **(double)** Lab 9 fs · **Lab 12 silicon teams begin** | L8 |
| 13 | Crash recovery; journalling; mmap & VM for applications | **(double)** Lab 10 mmap · Lab 11 crash assigned | L9 |
| 14 | Bring-up war stories; synthesis; beyond Luit (microkernels, RCU) | **VIVA 2** · Lab 12 silicon demos | L10, L11, L12 |

## 2. Assessment

Labs 55% (weights: util 4, syscall 4, pgtbl 5, traps 5, cow 6, thread 3, net 5, lock 5, fs 5, mmap 5, crash 5, silicon 3) · Viva 1 12% · Viva 2 18% · End-sem theory exam 15%. Optional challenges (lazy allocation in cow; MLFQ in thread; block device in silicon) add up to +2% each, capped at 100. Passing requires ≥35% in the viva component independently — the anti-outsourcing backstop.

**Viva protocol.** Examiner has the student's diffs and LLM log open. Three question classes: walk-your-own-code ("this line — why?"), counterfactual ("what breaks first if…"), transfer (a published seed question). Per question 0–3: cannot engage / describes / explains mechanism / reasons about change. First five students per examiner double-marked for calibration.

## 3. Autograder architecture

* **Public:** `make grade` = `tests/grade.py` (9 baseline tests) + per-lab `tests/labNN/` on each `release/labNN` branch. Runs in the course Docker image; CI runs it plus HAL=shakti/vega compile checks on every push.
* **Hidden:** staff overlay `tests/hidden/labNN/`; same harness, extra scenarios, different seeds; each hidden test ×3, must pass all (kills racy "solutions").
* **Anti-gaming:** forbidden-marker checks (printing ALL TESTS PASSED doesn't make it so); generated-files-clean check; behavior over strings (the persistence test actually reboots).
* **Crash harness (Lab 11):** SIGKILLs QEMU at exponentially-distributed points during a metadata storm, remounts, audits invariants; 200 trials; public seed disclosed for a practice subset only.

## 4. Git branch model

```
release/base-v1.0          what students clone (== tag base-v1.0)
release/lab01 … lab12      base + that lab's handout, tests, skeletons
staff/solution-lab01 … 12  reference solutions (never public)
staff/patches/             e.g. lab05-cow-solution.patch
```
Students fork release/labNN → work → CI → submit a commit hash. Handout fixes cherry-pick forward; every staff solution is CI-verified against hidden tests before its lab releases.

## 5. Staffing & workload

Per 120 students: 1 faculty + 6 TAs (20:1 lab ratio). TA week ≈ 8 h: two lab slots, one office hour, grading/triage 2 h, staff sync 1 h. Each viva round = 30 examiner-hours (120 × 15 min), covered by faculty + 4 senior TAs. Student workload targets the 8-credit norm (12–14 h/wk); labs aim for a 6–8 h median, with cow and net given two weeks each because MIT's data and ours agree they are the humps. Anonymous per-lab time polls feed next year's tuning.

## 6. Risk register

| Risk | L×I | Mitigation |
|------|-----|-----------|
| FPGA/board pool insufficient for Lab 12 | M×H | vendor simulator as equivalent demo path; 3-person teams; booking from week 10 |
| LLM outsourcing hollows learning | H×H | 35% viva floor; Luit's divergence from xv6 defeats pattern-matching; log audits |
| Toolchain drift breaks setups | M×M | pinned Docker image is the ONLY supported env; CI = grader |
| Hidden-test leak | L×H | per-year seed rotation; access-logged staff repo; behavior-not-string checks |
| Week-13 density (mmap + crash) | M×M | double-lab week; crash assigned with skeleton + practice seeds early; mmap scoped to the MIT baseline (no lazy-write-back extras) |
| Baseline bug found mid-semester | M×M | hotfix cherry-picked through release/*; grade.py pins behavior; bug bounty in bonus marks |
| TA turnover | M×M | TA_GUIDE.md + staff solutions + this file are the institutional memory |

## 7. Five-year roadmap

* **Y1:** run the 12-lab sequence; collect per-lab time and failure telemetry; Lab 12 on FPGA bitstreams.
* **Y2:** journalling (LuitFS v3) offered as a baseline option track; first physical-board cohort; public open-source release of the repository.
* **Y3:** virtio-net → a real MAC on VEGA; adoption kit for two partner institutes; 8-hart SMP scalability lab.
* **Y4:** research spine — semester projects (RCU-lite, io_uring-style rings) feeding B.Tech theses; FDT parser released standalone.
* **Y5:** cut Luit 2.0 from five years of patches under the same audit discipline; the course as the documented reference for indigenous-OS pedagogy.
