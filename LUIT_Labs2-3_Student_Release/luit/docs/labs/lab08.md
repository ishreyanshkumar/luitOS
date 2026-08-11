# Lab 8: lock — Parallelism & Locking

*Weight: 5% of course grade · You will touch: kernel/palloc.c, kernel/bio.c*

**Goal.** Remove the baseline's two deliberate bottlenecks — the global page-allocator lock and the single buffer-cache lock — and prove it with contention numbers.

**Tasks.**
1. *Memory allocator:* per-hart free lists; steal from a neighbor when empty, with lock acquisition ordered by hart index (write the invariant as a comment and defend it). Your Lab 5 refcounts must keep working.
2. *Buffer cache:* hash (dev, blockno) into buckets, one lock each; LRU by timestamp. Eviction may move a buf between buckets — get the ordering right and justify your scheme in comments.
3. Report before/after lock-contention counts from `alloctest` and `bcachetest` at CPUS=4.

**Regression contract.** usertests, cowtest, AND the persistence grade test — your faster cache must still put bytes on the actual disk.

**Viva seeds.** Why is eviction the hard part of the bucket design? Show a two-bucket deadlock and your prevention.

---

## Ground rules (all labs)

* Branch from `release/lab08`; `make grade LAB=8` must pass before submission; CI runs the same plus hidden tests.
* Your kernel must still pass **all baseline tests** — regressions cost marks even when the new feature works.
* The LLM policy for this lab is in `docs/LLM_POLICY.md`. Log every AMBER session as specified there.
