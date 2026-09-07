# TA / Instructor Notes — Luit Page-Fault Lab

## Purpose

This is a non-graded bridge from the completed Lab 3 information page to the page-fault mechanisms used by lazy allocation, COW, `mmap()`, and demand-paged `exec()`.

The student handout uses direct instructions. The core exercises are observational. One controlled guard-page experiment performs a real repair and retry. The COW and `mmap()` sections expose the mechanism without providing complete production implementations.

## Source version checked

The supplement was checked against `LUIT_Lab03_Student_Distribution_v1.2.3`.

Important source facts in that tree:

- `kernel/trap.c`: explicit fatal branch for user `scause == 13 || scause == 15`; instruction page fault 12 reaches the general unexpected-exception branch.
- `kernel/proc.c:growproc()`: positive `sbrk()` eagerly allocates, zeroes, and maps pages.
- `kernel/vm.c:uvmcopy()`: eager child-page allocation and copy.
- `kernel/riscv.h`: `PTE_COW` is bit 8.
- `kernel/palloc.c`: `kmem.refcnt` is a one-byte-per-managed-page array carved from RAM and protected by `kmem.lock`.
- `kernel/vm.c:copyout()`: validates `V`, `U`, and `W`; then uses `PTE2PA()` and `memmove()`.
- `kernel/fs.c:readi()`: with `user_dst == 1`, reads a block with `bread()` and invokes `copyout()` from `bp->data`.
- `kernel/bio.c`: `bcache` is static kernel data and contains `struct buf buf[NBUF]`; each buffer contains `data[BSIZE]`.
- `kernel/exec.c`: eager ELF loading, one unmapped guard page, then one initial user stack page. After exec, `p->sz` is the top of that initial stack page.
- `kernel/uservec.S`: no `satp` switch on user trap entry. It restores the kernel hart ID into `tp` before jumping to `usertrap()`.
- `kernel/proc.c:scheduler()`: installs a process page table before running the process and restores `kernel_pagetable` after switching back to the scheduler.

## GDB guidance

### Use the conditional page-fault breakpoint

The helper command:

```gdb
pfbreak
```

sets a conditional breakpoint at `usertrap()` only for `scause` 12, 13, or 15.

Do not recommend an unconditional `b usertrap` as the main breakpoint. It also stops on every system call.

### Obtain the current process without calling `myproc()` from GDB

While stopped in `usertrap()` or another kernel path for the current process, use:

```gdb
set $p = cpus[$tp].proc
```

This avoids executing a target function from GDB. In Luit, `uservec` restores the hart ID into `tp` before calling `usertrap()`.

### A/D bits are not the teaching distinction

For the USYSINFO experiment, require the relevant state:

```text
V=1, U=1, R=1, W=0
```

Do not require a particular `A` or `D` display. Those bits are not the point of the experiment and can depend on actual accesses and hardware behavior.

## Expected fault signatures

### `pfdemo load`

```text
scause = 13
stval  = 0x40000000
translation absent/invalid
```

### `pfdemo store`

```text
scause = 15
stval  = 0x7ffff000
leaf valid
U=1, R=1, W=0
```

### `pfdemo guard`

```text
scause = 15
stval  = initial guard-page VA
leaf absent/invalid
```

For this program, before any positive `sbrk()`:

```text
guard start = p->sz - 2 * PGSIZE
```

The formula is tied to the current eager `exec()` layout: one guard page followed by one stack page, with `p->sz` at the top of the stack.

### `pfdemo exec`

```text
scause = 12
stval  = 0x40000000
translation absent/invalid
```

The current `usertrap()` does not put 12 in the explicit 13/15 page-fault branch. It is killed through the general exception path.

## Controlled guard-page repair

The supplied patch is intentionally not a real guard-page policy.

It is safe for the demonstration because:

- `pfdemo guard` has not performed a positive `sbrk()` before the access;
- the computed guard address matches the eager `exec()` layout;
- the mapped page lies below `p->sz`, so normal process teardown includes it;
- the patch preserves fatal behavior if allocation or mapping fails;
- the handler does not advance `epc`;
- `sfence_vma()` is executed after the new mapping is installed.

Require students to revert this patch after observing repair and retry.

A robust GDB sequence is:

```gdb
pfbreak
c
# run pfdemo guard
set $p = cpus[$tp].proc
set $fault_epc = $sepc
ptewalk $p->pagetable $stval
b mappages
c
finish
ptewalk $p->pagetable $stval
clear mappages
p/x $fault_epc
p/x $p->tf->epc
c
```

The final `c` should let the original store retry successfully.

## COW-shaped debugger mutation

The handout changes a newly created heap-page PTE only after `growproc()` has mapped it and before the user first touches it.

Use:

```gdb
b kernel/syscall.c:71
```

At this source line, `growproc(n)` has already returned successfully in the supplied v1.2.3 source.

Then:

```gdb
set $p = cpus[$tp].proc
set $cowva = $p->sz - 4096
ptewalk $p->pagetable $cowva
set *$pf_leaf = (*$pf_leaf & ~0x4) | 0x100
```

This turns `W` off and the software `COW` bit on. It does not implement COW. No second process shares the page and the reference count remains the normal single-owner count. The experiment reproduces only the PTE state that causes the hardware store-fault entry.

The user has not yet accessed this newly allocated page, so the experiment modifies the PTE before the first user translation of that page. Restart QEMU after the experiment. Do not carry the debugger-created state into later observations.

The expected first user write then gives:

```text
scause = 15
V=1, U=1, W=0, COW=1
```

The baseline kernel should kill the process.

## Regular-file `read()` and `copyout()`

Use:

```gdb
b readi if user_dst == 1
```

The condition avoids stopping on `exec()`'s `readi(..., user_dst=0, ...)` calls.

The relevant source path is exactly:

```text
sys_read()
 -> fileread()
 -> readi(ip, 1, uaddr, ...)
 -> bread()
 -> bp->data
 -> copyout(myproc()->pagetable, dst, bp->data + offset, m)
```

At `kernel/fs.c:322` in v1.2.3, `copyout()` is called.

Useful observations:

```gdb
p bp->blockno
p/x &bp->data[0]
p/x dst
step
p/x dstva
p/x src
ptewalk $p->pagetable dstva
```

Explain that `bp->data` is not a special CPU register or disk address. It is kernel-owned RAM inside the static buffer cache. `copyout()` converts the destination user VA through the user's PTE, then writes to the physical RAM page through Luit's identity-mapped managed-RAM kernel mapping.

## COW and `copyout()`

The essential invariant is:

> Before any writer modifies a COW-shared data page, the kernel must ensure the writer has the correct writable ownership/mapping.

User stores enter through hardware `scause=15`. Kernel `copyout()` must inspect `PTE_COW` in software because its final `memmove()` uses a kernel-accessible RAM address rather than executing the original user store through the user PTE.

If a COW resolver changes the PTE to a different physical page, `copyout()` must use the repaired PTE before deriving the final physical destination.

Do not provide a complete `cowfault()` implementation in this lab.

## `mmap()` section

The VMA example is conceptual. The current tree has no complete `mmap()` implementation.

The teaching point is that these two cases can have identical hardware state:

```text
illegal VA:       missing PTE, scause=13
valid lazy mmap:  missing PTE, scause=13
```

VMA metadata changes the kernel policy.

For the example:

```text
VMA.start = 0x40000000
VMA.off   = 0x2000
stval     = 0x40001388
```

The correct page and file offset are:

```text
fault_page = 0x40001000
file_off   = 0x3000
```

## Demand-paged `exec()` section

The current `exec()` is eager. It already demonstrates the metadata a lazy version would need to preserve or reconstruct:

- virtual segment location;
- `memsz`;
- `filesz`;
- file offset;
- ELF R/W/X flags;
- a stable reference to the executable backing object while lazy faults remain possible.

For a production lazy implementation, be careful with unaligned ELF segments. The simple formula shown in the handout is explained as a simple aligned-segment case. The existing eager `loadseg()` should be used to discuss the precise `seg_off` and `dst_off` handling.

A fully demand-paged text segment also requires a recoverable path for `scause=12`.

## Common conceptual errors to correct

1. **“Page fault means PTE_V=0.”** Incorrect. USYSINFO demonstrates a valid PTE with a write-permission fault.
2. **“Advance EPC after repairing a page fault.”** Incorrect. The failed instruction must retry.
3. **“PTE_U=1 means the kernel cannot touch the physical page.”** Incorrect. `PTE_U` controls access through that mapping. The kernel can reach managed RAM through supervisor mappings.
4. **“The COW reference count is a CPU register.”** Incorrect. It is kernel metadata in RAM.
5. **“The buffer cache is on disk.”** Incorrect. It is kernel RAM holding cached copies of disk blocks.
6. **“mmap faults have a special hardware scause.”** Incorrect. The VMA is software metadata; the hardware reports the ordinary page fault.
7. **“copyout will automatically trigger the same user store fault.”** Incorrect for this Luit implementation. `copyout()` walks the PTE in software and copies through the kernel-accessible physical mapping.
8. **“sfence.vma fixes the page table.”** Incorrect. The kernel must first change the PTE. `sfence.vma` invalidates stale translation state after the page-table change when required.

