# Lab 3: pgtbl — Page Tables

*Weight: 5% of course grade · You will touch: kernel/vm.c, kernel/proc.c, kernel/riscv.h*

**Goal.** Read and construct page tables by hand.

**Tasks.**
1. *Speed up getpid():* map a read-only USYSCALL page into every process at a fixed VA containing `struct usyscall { int pid; }`, and reimplement `getpid()` in user space with zero traps.
2. *vmprint:* extend `vmprint()` to print the user half of a page table as an indented tree with permission bits, and call it for the first process at exec.
3. *pgaccess:* a syscall reporting, as a bitmask, which pages in a range have been accessed since the last call — read and clear PTE_A.

**Luit note.** Luit maps the kernel into every address space (no trampoline); user page tables borrow the kernel's upper entries, protected by the absence of PTE_U. Your vmprint must skip the borrowed entries — and you must be able to say *why* that borrowing is safe.

**Viva seeds.** Why can't the USYSCALL page be writable? What breaks first if uvmcreate stopped borrowing kernel entries?

---

## Ground rules (all labs)

* Branch from `release/lab03`; `make grade LAB=3` must pass before submission; CI runs the same plus hidden tests.
* Your kernel must still pass **all baseline tests** — regressions cost marks even when the new feature works.
* The LLM policy for this lab is in `docs/LLM_POLICY.md`. Log every AMBER session as specified there.
