# Lab 10: mmap — Memory-Mapped Files

*Weight: 5% of course grade · You will touch: kernel/proc.*, trap.c, vm.c, sysfile.c*

**Goal.** Memory-mapped files: the convergence of virtual memory, page faults, the file layer, and fork semantics.

**Tasks.**
1. `mmap(0, len, prot, flags, fd, 0)` with MAP_SHARED and MAP_PRIVATE, fully lazy: no pages at map time; fault them in via `readi` from the marked hook in `usertrap` — the same line your Lab 5 COW handler lives on.
2. `munmap`: MAP_SHARED writes dirty pages back via `writei`; partial unmaps from either end.
3. fork inherits mappings; exit unmaps them. A fixed VMA table (16 slots in `struct proc`) is fine.

**Viva seeds.** Where does MAP_PRIVATE-after-fork meet your COW machinery? What are the write-back guarantees at munmap versus exit versus crash — and which lab fixes the crash case?

---

## Ground rules (all labs)

* Branch from `release/lab10`; `make grade LAB=10` must pass before submission; CI runs the same plus hidden tests.
* Your kernel must still pass **all baseline tests** — regressions cost marks even when the new feature works.
* The LLM policy for this lab is in `docs/LLM_POLICY.md`. Log every AMBER session as specified there.
