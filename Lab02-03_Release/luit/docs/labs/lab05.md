# Lab 5: cow — Copy-on-Write Fork

*Weight: 6% of course grade · You will touch: kernel/vm.c, kernel/trap.c, kernel/palloc.c*

**Goal.** Replace the baseline's eager `uvmcopy` with copy-on-write. The refcount machinery in `palloc.c` has been waiting for you since day one, and `PTE_COW` (RSW bit 8) is reserved in `riscv.h`.

**Tasks.**
1. `uvmcopy`: map parent pages into the child read-only + PTE_COW; bump refcounts; copy nothing.
2. Store-page-faults on PTE_COW pages (the marked hook in `usertrap`): refcount 1 → just set PTE_W; else allocate, copy, remap, decref.
3. `copyout` into a COW page must trigger the same copy — kernel writes don't take user faults.
4. `pfree` frees only at refcount zero.

**Regression contract.** The baseline's `test_fork_isolation` and `test_no_leak` (20 fork/exit cycles, zero pages leaked) were designed for this exact moment: isolation must still hold, and the refcounts must balance.

**Challenge (optional, +2%).** Lazy allocation: make `sbrk` a promise and deliver pages from the same fault handler. The hook comment marks where.

**Viva seeds.** Why is the refcount check-and-act a critical section? What is the risk of copying inside the fault handler under memory pressure?

---

## Ground rules (all labs)

* Branch from `release/lab05`; `make grade LAB=5` must pass before submission; CI runs the same plus hidden tests.
* Your kernel must still pass **all baseline tests** — regressions cost marks even when the new feature works.
* The LLM policy for this lab is in `docs/LLM_POLICY.md`. Log every AMBER session as specified there.
