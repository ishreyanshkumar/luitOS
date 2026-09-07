# CS3106L — Non-Graded Lab: Page Faults in Luit

**Theme:** Observe → Diagnose → Repair → Retry

**Assessment:** None. You do not submit this lab. You use it to understand how page faults work in Luit before you implement larger virtual-memory features.

## 1. What you will learn

In the previous lab, you created the read-only information page at:

```text
USYSINFO_VA = 0x7FFFF000
```

That page gives you a useful starting point. Its PTE is valid and user-readable, but it is not user-writable.

In this lab, you will examine several different reasons for a page fault. You will use GDB to inspect the faulting virtual address and the page-table entry. You will also repair one controlled fault and observe the same user instruction run again.

By the end, you should be able to explain:

- an instruction page fault: `scause = 12`;
- a load page fault: `scause = 13`;
- a store page fault: `scause = 15`;
- the roles of `scause`, `stval`, and `sepc`;
- the difference between a missing PTE and a permission fault;
- why the stack guard page must normally remain unmapped;
- why the current `sbrk()` implementation is eager;
- how a recoverable page fault installs or updates a PTE and retries the same instruction;
- how COW uses a store page fault;
- why kernel `copyout()` also needs to understand COW;
- how `mmap()` uses VMA metadata to classify a missing-PTE fault;
- what metadata a demand-paged `exec()` would need.

You will **not** implement complete COW or complete `mmap()` in this lab. You will inspect the exact mechanisms that those features use.

---

## 2. Use your completed Lab 3 tree

Use a scratch copy or a scratch Git branch of your **completed Lab 3** Luit tree.

Do not use an untouched Lab 3 starter tree for the USYSINFO experiment. Your completed Lab 3 must already map the information page correctly.

Before you modify anything, inspect these files:

```text
kernel/trap.c
kernel/vm.c
kernel/proc.c
kernel/palloc.c
kernel/syscall.c
kernel/file.c
kernel/exec.c
kernel/fs.c
kernel/bio.c
kernel/riscv.h
```

Confirm these facts in the supplied Luit code:

1. `usertrap()` has an explicit branch for user load and store page faults, `scause = 13` and `scause = 15`.
2. The current response to those faults is fatal. Luit prints the fault and marks the process as killed.
3. `growproc()` performs eager positive `sbrk()`: it calls `palloc()`, zeroes the page, and calls `mappages()` before returning to user mode.
4. `uvmcopy()` performs eager `fork()`: it allocates a new page for the child and copies the parent's page.
5. `PTE_COW` is already defined in `kernel/riscv.h` using RISC-V software-reserved PTE bit 8.
6. `kernel/palloc.c` already contains reference-count support. `kmem.refcnt` is kernel-managed metadata stored in RAM and protected by `kmem.lock`.
7. `copyout()` currently rejects a destination PTE if `PTE_W` is clear.
8. `kernel/fs.c:readi()` calls `copyout()` when `user_dst == 1`.
9. Luit does not contain a complete `mmap()` implementation in this tree.

These observations are important. You will refer to the same code throughout the lab.

---

## 3. Add the demonstration program and GDB helpers

The lab supplement contains:

```text
user/pfdemo.c
docs/pagefault.gdb
docs/temporary_guard_repair.patch
```

Copy `user/pfdemo.c` into the `user/` directory of your completed Luit tree.

Copy `docs/pagefault.gdb` and `docs/temporary_guard_repair.patch` into the `docs/` directory of your Luit tree.

Add `user/pfdemo` to `UPROGS` in the Makefile. For example, the end of the list can look like:

```make
... user/usertests user/forktest user/pfdemo
```

Rebuild:

```bash
make clean
make
```

The demonstration program supports these commands:

```text
pfdemo load       load from an unmapped user virtual address
pfdemo store      store to the read-only USYSINFO page
pfdemo guard      store into the unmapped stack guard page
pfdemo exec       fetch an instruction from an unmapped user virtual address
pfdemo eager      observe eager sbrk() allocation
pfdemo readpath   follow regular-file read() into copyout()
```

Several commands deliberately kill only the `pfdemo` process. That is expected. The Luit kernel and shell should continue running.

---

# Part A — Read a page fault correctly

## 4. Start QEMU and GDB

Use two terminals.

### Terminal 1

From the Luit root directory, run:

```bash
make qemu-gdb CPUS=1
```

Using one hart makes the process and page-table state easier to follow.

### Terminal 2

From the same Luit root directory, run:

```bash
gdb-multiarch kernel.elf
```

The supplied `.gdbinit` normally connects to QEMU on port 1234.

If GDB does not auto-load `.gdbinit`, follow the safe-path instruction printed by GDB, or connect manually:

```gdb
target remote localhost:1234
symbol-file kernel.elf
```

Load the page-fault helpers:

```gdb
source docs/pagefault.gdb
```

You should see a message listing these commands:

```text
pfbreak
pfstate
ptewalk
pteflags
satpcheck
```

Create a **conditional page-fault breakpoint**:

```gdb
pfbreak
c
```

`pfbreak` stops at `usertrap()` only when `scause` is 12, 13, or 15. Do not use an unconditional `b usertrap` for the main experiments. An unconditional breakpoint also stops on every system call and makes normal shell activity difficult to follow.

When a page fault stops in `usertrap()`, begin with:

```gdb
pfstate
satpcheck
```

Always interpret these values first:

```text
scause   What kind of trap occurred?
stval    Which virtual address caused the page fault?
sepc     Which user instruction failed?
satp     Which page-table root is active?
```

While you are stopped inside `usertrap()`, the current process pointer can be obtained without calling a kernel function:

```gdb
set $p = cpus[$tp].proc
```

Luit's trap entry restores the hart ID into `tp` before it calls `usertrap()`. Therefore `cpus[$tp].proc` identifies the process that faulted.

---

## 5. Experiment 1 — Load from an unmapped address

At the Luit shell, run:

```text
pfdemo load
```

GDB should stop in `usertrap()`.

Run:

```gdb
pfstate
set $p = cpus[$tp].proc
ptewalk $p->pagetable $stval
x/4i $sepc
```

You should interpret the state as:

```text
operation    : user load
scause       : 13, load page fault
stval        : 0x40000000
PTE state    : the translation is absent or invalid
sepc         : points to the load instruction that did not complete
```

The important point is not only that `scause = 13`. The page-table walk tells you **why** the load could not be translated.

Continue:

```gdb
c
```

The baseline kernel should kill `pfdemo`. The shell should remain alive.

### Think about this fault

Suppose `0x40000000` were inside a valid file-backed `mmap()` region, but its PTE had not been installed yet.

Would the hardware use a different `scause`?

No. It would still be a load page fault. Hardware does not know whether the missing mapping is illegal, lazy heap memory, `mmap()`, or demand-paged executable code. The kernel uses software metadata to make that decision.

---

## 6. Experiment 2 — Store to the read-only USYSINFO page

At the Luit shell, run:

```text
pfdemo store
```

When GDB stops, run:

```gdb
pfstate
set $p = cpus[$tp].proc
ptewalk $p->pagetable $stval
x/4i $sepc
```

The faulting address should be:

```text
0x7FFFF000
```

Now inspect the leaf PTE carefully. The relevant bits should show:

```text
V = 1
U = 1
R = 1
W = 0
```

You may also see hardware-maintained `A` or `D` state depending on previous accesses. Do not use `A` or `D` to classify this experiment. The important fact is that the mapping is valid and user-readable but not writable.

The CPU reports:

```text
scause = 15, store page fault
```

This gives you a critical rule:

> A page fault does not always mean that the PTE is missing. A valid PTE can also fault because the requested operation violates its permissions.

Compare two future cases:

```text
USYSINFO page:
V=1, U=1, R=1, W=0, COW=0
-> genuinely read-only
-> reject a write

COW page:
V=1, U=1, R=1, W=0, COW=1
-> temporarily read-only because it is shared
-> a COW handler may repair the mapping before the write
```

Continue and allow only the `pfdemo` process to exit.

---

## 7. Experiment 3 — Store into the stack guard page

At the Luit shell, run:

```text
pfdemo guard
```

When GDB stops, run:

```gdb
pfstate
set $p = cpus[$tp].proc
p/x $p->sz
ptewalk $p->pagetable $stval
```

In Luit's current eager `exec()` layout, `p->sz` is set to the top of the initial stack page. `exec()` places one unmapped guard page immediately below that stack page.

For this demonstration program, no positive `sbrk()` occurs before the guard access. Therefore the guard page begins at:

```text
p->sz - 2 * PGSIZE
```

`pfdemo guard` obtains the current `p->sz` through `sbrk(0)` and writes into that guard page.

Compare Experiment 2 and Experiment 3:

```text
USYSINFO store
    scause = 15
    leaf PTE exists
    PTE_W = 0

Guard-page store
    scause = 15
    leaf PTE is absent or invalid
```

The same `scause` can therefore describe different page-table states.

For a correct diagnosis, use all of these together:

```text
scause
stval
sepc
PTE state
kernel VM metadata
```

Continue and let `pfdemo` exit.

---

## 8. Experiment 4 — Instruction page fault

At the Luit shell, run:

```text
pfdemo exec
```

When GDB stops, run:

```gdb
pfstate
set $p = cpus[$tp].proc
ptewalk $p->pagetable $stval
x/4i $sepc
```

You should see:

```text
scause = 12, instruction page fault
stval  = 0x40000000
```

The attempted instruction fetch has no valid translation.

Now inspect `kernel/trap.c`.

The current Luit code gives `scause = 13` and `scause = 15` an explicit page-fault branch. `scause = 12` reaches the general unexpected-exception path and the process is killed.

That behavior is consistent with the current **eager** `exec()`. Luit loads the executable text before it begins user execution.

A demand-paged `exec()` would need a different policy. It would have to treat `scause = 12` as potentially recoverable because the first instruction page could intentionally be absent until the CPU first fetches from it.

Continue and let `pfdemo` exit.

---

# Part B — Observe eager `sbrk()`

## 9. Experiment 5 — See when physical memory is allocated

Remove the conditional page-fault breakpoint:

```gdb
clear usertrap
c
```

At the Luit shell, run:

```text
pfdemo eager
```

The program performs these actions:

```text
1. read the current number of free physical pages;
2. call sbrk(PGSIZE);
3. read the free-page count again;
4. write to the newly returned page;
5. read the free-page count again.
```

You should observe that physical-memory consumption occurs during `sbrk()`, before the first user write to the returned page.

Do not require the free-page count to fall by exactly one in every possible address-space layout. If a new page-table page is also required, page-table allocation can consume another physical page. The important invariant is that the allocation work happens **before first touch**.

Now inspect `growproc()` in `kernel/proc.c`.

For a positive `sbrk()`, the current code performs:

```text
palloc()
   |
memset(..., 0, PGSIZE)
   |
mappages(...)
   |
return to user mode
```

That is eager allocation.

A lazy positive `sbrk()` would record the enlarged logical region first and leave the new leaf PTE absent. A legitimate first access would then cause a page fault and allocate the page on demand.

---

# Part C — Repair one page fault and retry the same instruction

## 10. Temporarily turn the guard page into a demand-zero page

This experiment is deliberately temporary. A real guard page must remain unmapped. You are changing its behavior only to observe the complete recoverable page-fault path.

Use the supplied patch:

```text
docs/temporary_guard_repair.patch
```

From the Luit root directory, apply it:

```bash
patch -p1 < docs/temporary_guard_repair.patch
make clean
make
```

Restart QEMU and GDB because the kernel has changed.

Load the helper commands and create the conditional page-fault breakpoint again:

```gdb
source docs/pagefault.gdb
pfbreak
c
```

The temporary handler performs this policy only when the faulting page is the initial stack guard page used by `pfdemo guard`:

```text
page fault
   |
round stval down to a page boundary
   |
recognize the guard-page VA used by this experiment
   |
palloc()
   |
zero the new physical page
   |
mappages(..., PTE_R | PTE_W | PTE_U)
   |
sfence.vma
   |
return without changing p->tf->epc
```

### Observe the mapping before repair

At the Luit shell, run:

```text
pfdemo guard
```

At the first page-fault stop:

```gdb
pfstate
set $p = cpus[$tp].proc
set $fault_epc = $sepc
ptewalk $p->pagetable $stval
```

You should see that the leaf mapping is absent or invalid.

Set a temporary breakpoint on `mappages()` and continue:

```gdb
b mappages
c
```

You should now be inside the `mappages()` call made by the temporary repair path.

Inspect its arguments:

```gdb
p/x va
p/x size
p/x pa
p/x perm
```

The intended virtual address should be the page-aligned guard address. The size should be one page. The permissions should include user, read, and write.

Return from `mappages()`:

```gdb
finish
```

Inspect the PTE again:

```gdb
ptewalk $p->pagetable $stval
```

The leaf should now be valid and should contain the relevant bits:

```text
V=1, U=1, R=1, W=1
```

Remove the `mappages()` breakpoint so it does not distract you:

```gdb
clear mappages
```

Check the faulting instruction address:

```gdb
p/x $sepc
p/x $fault_epc
p/x $p->tf->epc
```

`$fault_epc` and the saved return PC in `p->tf->epc` should still identify the faulting user instruction. The page-fault handler did **not** add 4.

Continue:

```gdb
c
```

The same user store is retried. It should now succeed because the PTE has been installed.

### Why you must not use `epc += 4`

For an `ecall`, Luit intentionally returns to the instruction after `ecall`:

```text
ecall
   |
trap
   |
p->tf->epc += 4
   |
return after ecall
```

For a recoverable page fault, the load, store, or instruction fetch did not complete:

```text
faulting instruction
   |
page fault
   |
repair translation or permission
   |
do not advance epc
   |
return to the same instruction
   |
instruction retries
```

This rule is fundamental to lazy allocation, COW, `mmap()`, and demand-paged `exec()`.

### Restore the real guard-page behavior

After you finish this experiment, restore the original `kernel/trap.c` from your scratch branch or copy. Rebuild and restart Luit.

Do not keep the demand-zero guard behavior. The real guard page is useful because it is intentionally unmapped.

---

# Part D — Create the hardware shape of a COW fault

## 11. Inspect the COW support that already exists

Open these files:

```text
kernel/riscv.h
kernel/palloc.c
kernel/vm.c
```

Find:

```c
#define PTE_COW (1L << 8)
```

Then find:

```text
kmem.refcnt
palloc_ref_inc()
palloc_ref_get()
pfree()
```

Notice exactly where the reference-count metadata is stored. `palloc_init()` carves space for `kmem.refcnt` out of physical RAM near the beginning of the allocator-managed area. The kernel accesses that metadata through its kernel mapping. It is not a CPU register.

Also inspect `uvmcopy()` in `kernel/vm.c`.

The current code allocates a new physical page for the child and copies the parent's page. It is eager.

A COW design changes the initial state to this:

```text
before fork
Parent VA -> physical page P
PTE_W = 1
ref(P) = 1

immediately after COW fork
Parent VA -> physical page P, W=0, COW=1
Child  VA -> physical page P, W=0, COW=1
ref(P) = 2

child stores to the page
        |
        v
scause = 15
        |
        v
kernel sees W=0 and COW=1
        |
        v
obtain a private writable page when required
        |
        v
update the child's PTE
        |
        v
retry the same store
```

The CPU generates the store page fault because `W=0`. The kernel decides that the fault is recoverable because of software-maintained COW state.

---

## 12. GDB experiment — change one new page into a COW-shaped PTE

You can observe the COW hardware entry path without implementing COW.

Use a clean kernel with the temporary guard-page patch removed.

In GDB, remove the page-fault breakpoint if it exists:

```gdb
clear usertrap
```

Set a breakpoint at the return line of `sys_sbrk()` after `growproc()` has succeeded:

```gdb
b kernel/syscall.c:71
c
```

At the Luit shell, run:

```text
pfdemo eager
```

When GDB stops at `kernel/syscall.c:71`, check that the current process is `pfdemo`:

```gdb
set $p = cpus[$tp].proc
p $p->name
p/x $p->sz
```

`growproc()` has already increased `p->sz` by one page. The page returned by this `sbrk(PGSIZE)` therefore starts at:

```gdb
set $cowva = $p->sz - 4096
```

Walk that mapping:

```gdb
ptewalk $p->pagetable $cowva
```

The leaf should be valid and writable.

Now change only its software-visible PTE state:

```gdb
set *$pf_leaf = (*$pf_leaf & ~0x4) | 0x100
pteflags *$pf_leaf
```

The constants used above correspond to:

```text
0x4   = PTE_W
0x100 = PTE_COW
```

You have changed:

```text
W   : 1 -> 0
COW : 0 -> 1
```

You have not changed the physical page. You have also not created a second sharing process and you have not incremented the page reference count. Therefore this is **not a real COW mapping**. It only reproduces the PTE permission/software-bit state that causes the hardware store-fault entry used by COW.

This page has just been created by `sbrk()` and the user has not accessed it yet. Therefore this experiment changes the PTE before the first user translation of that new page. Restart Luit after this experiment rather than relying on this debugger-created state for any later work.

Remove the `sys_sbrk()` breakpoint and recreate the conditional page-fault breakpoint:

```gdb
clear kernel/syscall.c:71
pfbreak
c
```

The program will continue until it executes its first store to the new page.

When GDB stops in `usertrap()`, run:

```gdb
pfstate
set $p = cpus[$tp].proc
ptewalk $p->pagetable $stval
```

You should observe:

```text
scause = 15
PTE_V  = 1
PTE_U  = 1
PTE_W  = 0
PTE_COW= 1
```

The baseline kernel still kills the process because a complete COW fault handler is not part of this lab.

The important result is that you have observed the exact **hardware entry condition** for a COW write fault.

Restart QEMU after this experiment so that all page-table state returns to normal.

---

# Part E — Follow `read()` into `copyout()`

## 13. Trace a regular-file read

Use a clean Luit boot.

Do not set the general page-fault breakpoint for this experiment.

In GDB, set a conditional breakpoint on `readi()` only when it is copying file data to a user destination:

```gdb
b readi if user_dst == 1
c
```

At the Luit shell, run:

```text
pfdemo readpath
```

The condition `user_dst == 1` is important. `exec()` also calls `readi()`, but it uses `user_dst == 0` while it loads an ELF into kernel-allocated pages. The condition lets you stop on the ordinary `read(fd, user_buf, n)` path instead.

When GDB stops in `readi()`, inspect:

```gdb
set $p = cpus[$tp].proc
p $p->name
p/x dst
p n
p off
ptewalk $p->pagetable dst
```

`dst` is the user virtual address that ultimately came from the `buf` argument of:

```c
read(fd, buf, n)
```

Now look at the `readi()` loop in `kernel/fs.c`.

The important path is:

```text
read(fd, buf, n)
    |
sys_read()
    |
fileread()
    |
readi(..., user_dst=1, ...)
    |
bread()
    |
bp->data
    |
copyout(pagetable, user_buf, bp->data + offset, n)
```

Set a source breakpoint on the `copyout()` call in `readi()`:

```gdb
b kernel/fs.c:322
c
```

At that line, inspect the buffer-cache object and both addresses:

```gdb
p bp->blockno
p/x bp
p/x &bp->data[0]
p/x dst
```

In this Luit implementation, the buffer cache is the static kernel object `bcache` in `kernel/bio.c`. Each `struct buf` contains:

```c
uint8 data[BSIZE];
```

Therefore `bp->data` is kernel-owned memory. The buffer-cache bytes are stored in RAM and are accessible through the kernel mapping.

Now step into `copyout()`:

```gdb
step
```

Inside `copyout()`, inspect:

```gdb
p/x dstva
p/x src
p/x len
set $p = cpus[$tp].proc
ptewalk $p->pagetable dstva
```

The source and destination have different roles:

```text
src
  -> kernel buffer-cache memory
  -> kernel-owned mapping

dstva
  -> user virtual address
  -> PTE has PTE_U
```

`copyout()` walks the user page table, obtains the physical page behind `dstva`, checks that the user PTE is writable, and then performs the kernel-side memory copy.

After you understand the path, remove the breakpoints:

```gdb
clear readi
clear kernel/fs.c:322
```

---

## 14. Why `copyout()` needs a separate COW path

Read this current code in `copyout()`:

```c
if (!(*pte & PTE_W)) return -1;
```

Now imagine that the destination page after a COW `fork()` has:

```text
V=1, U=1, R=1, W=0, COW=1
```

A user-mode store to that page naturally causes a store page fault.

`copyout()` is different. The kernel has already received a user virtual address. It walks the user's page table in software, converts the user mapping to a physical address, and copies through the kernel-accessible RAM mapping.

Therefore the two COW entry paths are:

```text
user performs a store
        |
CPU checks user PTE
        |
W=0
        |
scause=15
        |
COW handler

kernel performs copyout()
        |
copyout() checks user PTE in software
        |
W=0, COW=1
        |
copyout() invokes the same COW break-sharing logic
```

A future COW-aware `copyout()` must not simply reject every `W=0` destination. It must distinguish a genuinely read-only page from a COW page.

If the COW handler changes the PTE so that the user VA points to a new private physical page, `copyout()` must re-read or re-walk the PTE before it calculates the destination physical address. Otherwise it could continue using stale information and write to the old shared page.

You do not implement the complete COW path here. You must be able to explain why this second entry path exists.

---

# Part F — Understand `mmap()` as a page-fault policy

## 15. Reuse the same missing-PTE fault from Experiment 1

Experiment 1 gave you:

```text
scause = 13
stval  = 0x40000000
PTE    = absent
```

The current Luit kernel treats that address as illegal and kills the process.

Now imagine that the process also has this kernel-maintained VMA metadata:

```text
VMA.start = 0x40000000
VMA.len   = 0x3000
VMA.file  = file/inode F
VMA.off   = 0x0000
VMA.prot  = READ
```

The hardware fault does not change. The kernel's interpretation changes.

A file-backed `mmap()` fault handler would conceptually perform:

```text
1. page-align stval;
2. find a VMA containing that virtual address;
3. check that the attempted load/store/fetch is allowed by the VMA;
4. obtain a physical page;
5. calculate which file bytes back this page;
6. read or obtain those bytes;
7. install the user PTE with the correct permissions;
8. invalidate a stale translation if required;
9. return without advancing epc;
10. let the same user instruction retry.
```

The key file-offset formula is:

```text
file_offset = vma.off + (fault_page - vma.start)
```

### Calculate this example

Suppose:

```text
VMA.start = 0x40000000
VMA.off   = 0x2000
stval     = 0x40001388
```

First page-align the faulting address:

```text
fault_page = 0x40001000
```

Then calculate the displacement inside the VMA:

```text
0x40001000 - 0x40000000 = 0x1000
```

Then calculate the backing file offset:

```text
0x2000 + 0x1000 = 0x3000
```

So the page beginning at user VA `0x40001000` is backed by file data beginning at offset `0x3000`.

The VMA is what makes the missing PTE meaningful. It records that the address is valid and tells the kernel what should appear there.

---

# Part G — Connect instruction page faults to demand-paged `exec()`

## 16. Inspect the ELF metadata that eager `exec()` already uses

Open `kernel/exec.c` and `kernel/elf.h`.

The current eager `exec()` reads ELF program headers. For each loadable segment, it already uses information such as:

```text
virtual address
memory size, memsz
file-backed size, filesz
file offset
R/W/X flags
executable inode while loading
```

The eager implementation immediately allocates pages, zeroes them, reads the file-backed bytes, and installs PTEs.

A demand-paged version would retain enough of this segment information after `exec()` so that a later page fault could answer:

```text
Does this faulting VA belong to a valid ELF segment?
Which executable file backs it?
Which file offset corresponds to this page?
How many bytes come from the file?
Which bytes must remain zero?
Should the final PTE be readable, writable, or executable?
```

For a simple aligned segment, the backing offset has the familiar form:

```text
segment.file_off + (fault_page - segment.virtual_start)
```

A complete implementation must also handle the ELF segment's actual alignment and the difference between `filesz` and `memsz` correctly. The current eager `loadseg()` is useful because it already shows the required `filesz`/`memsz` logic.

Why are both sizes required?

```text
filesz
  -> bytes that actually exist in the ELF file

memsz
  -> total bytes the segment occupies in memory
```

When `memsz > filesz`, the extra bytes are zero-filled memory, such as BSS. They must not be read as nonexistent file bytes.

A fully demand-paged executable must also consider `scause = 12`, because the CPU may fault while fetching an instruction from an executable text page that has not yet been installed.

---

# Part H — Build one decision process for all page faults

## 17. Use this reasoning at every user page fault

```text
                 user memory access fails
                          |
                          v
              scause = 12 / 13 / 15
              stval  = faulting VA
              sepc   = faulting instruction
                          |
                          v
               inspect PTE + VM metadata
                          |
        +-----------------+------------------+
        |                 |                  |
        v                 v                  v
 illegal/guard      valid COW page     valid lazy region,
                    with W=0           mmap VMA, or
                                       lazy ELF segment
        |                 |                  |
        v                 v                  v
      kill          break sharing       obtain backing page
                    or change PTE        zero/file/ELF data
                         \                  /
                          +--------+--------+
                                   |
                            install/update PTE
                                   |
                           sfence.vma if needed
                                   |
                           do not advance epc
                                   |
                                  sret
                                   |
                         same instruction retries
```

The page fault is the **mechanism**.

Lazy allocation, COW, `mmap()`, and demand-paged `exec()` are different **policies** for deciding whether the fault is legal and, if it is legal, how to repair it.

---

## 18. Questions you should be able to answer in GDB

When you are stopped at a page fault, make sure you can answer these questions directly from the machine state and source code:

1. What is the value of `scause`?
2. Is this an instruction fetch, load, or store fault?
3. What exact virtual address is in `stval`?
4. Which user instruction is identified by `sepc`?
5. Is the leaf PTE absent, invalid, or valid?
6. If the PTE is valid, which of `R`, `W`, `X`, and `U` are set?
7. If the PTE is valid, which physical page number does it contain?
8. Why is the USYSINFO write a permission fault rather than a missing-PTE fault?
9. Why is the stack guard page normally left unmapped?
10. Why does a recoverable page fault return to the same `sepc`?
11. Why must you not apply the system-call rule `epc += 4` to a recoverable page fault?
12. Why does `satp` still refer to the current process page table while Luit executes `usertrap()`?
13. What software metadata distinguishes an illegal missing PTE from a lazy or `mmap()` missing PTE?
14. Why does COW intentionally clear `PTE_W`?
15. Where is Luit's physical-page reference-count metadata stored?
16. Why can `copyout()` need COW handling even though no user store instruction is executing?
17. Why must `copyout()` re-read a PTE after COW repair?
18. What fields must a VMA retain for file-backed `mmap()`?
19. What ELF segment information must a demand-paged `exec()` retain?
20. Why does demand-paged executable text require handling `scause = 12`?

---

## 19. Completion checklist

You should be able to explain each item without memorizing a particular code listing:

- [ ] `scause = 12`, `13`, and `15`.
- [ ] the different roles of `scause`, `stval`, and `sepc`.
- [ ] an absent-PTE fault versus a permission fault.
- [ ] the purpose of Luit's stack guard page.
- [ ] how a kernel repairs a mapping and retries the same instruction.
- [ ] why baseline Luit `sbrk()` is eager.
- [ ] what a lazy positive `sbrk()` would defer.
- [ ] why COW uses `W=0` together with software COW metadata.
- [ ] where the page reference count is stored and who updates it.
- [ ] why `copyout()` needs a software COW path.
- [ ] why `copyout()` must use the repaired PTE after COW.
- [ ] what a VMA records for `mmap()`.
- [ ] how a page fault can calculate the file offset for an `mmap()` page.
- [ ] what ELF segment metadata is required for demand-paged `exec()`.
- [ ] why `filesz` and `memsz` are different.
- [ ] why `sfence.vma` is required when stale translations may exist after a PTE change.
- [ ] why a repaired page fault returns to the same user instruction.

