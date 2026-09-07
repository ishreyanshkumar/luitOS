# BrahmaputraOS / Luit — TA Implementation Guide

**Read this before you walk into the lab.** Everything in the accompanying
`luit/` tree compiles, boots, and passes its tests. Build it yourself first,
break it deliberately, and only then face the students.

This guide talks to *you*, the TA. Where it says "you," it means you.

---

## 0. Before the first lab: get the reference kernel running

Do this on your own machine, tonight, not five minutes before the session.

```bash
sudo apt-get install -y gcc-riscv64-unknown-elf qemu-system-misc gdb-multiarch
cd luit
make
make qemu
```

You should see, within two seconds:

```
=========================================
  BrahmaputraOS / kernel Luit
  IIT Guwahati - CS3106L
=========================================
fdt   : blob at 0x0000000087e00000 (6790 bytes)
uart  : 0x0000000010000000  (discovered, not hardcoded)
plic  : 0x000000000c000000
memory: 0x0000000080000000 + 128 MiB
harts : 4
palloc: RAM 0x0000000080000000..0x0000000088000000, managing 31927 free pages (124 MiB)
hart 0: online
hart 3: online
hart 2: online
hart 1: online

init: starting BrahmaputraOS userland
luit$
```

Type `usertests` at the prompt. You must get:

```
=== BrahmaputraOS usertests ===
  [ OK ] wait() returns the child's exit status
  [ OK ] bad syscall number rejected
  [ OK ] hostile user pointers rejected (kernel still alive)
  [ OK ] sbrk: heap grows and is writable
  [ OK ] preemptive scheduling: both CPU-bound children completed
  [ OK ] copy-on-write: parent and child are isolated
  [ OK ] no page leak across 20 fork/exit cycles (refcounts are correct)
=== ALL TESTS PASSED ===
```

Quit QEMU with `Ctrl-A` then `x`.

**Then run the three adaptivity configurations.** These are the ones that prove
the kernel is not a toy, and you will be asked about them:

```bash
make qemu NCPU=1 MEM=64M      # must report harts : 1,  60 MiB
make qemu NCPU=8 MEM=512M     # must report harts : 8, 508 MiB
make qemu NCPU=2 MEM=128M     # must report harts : 2, 124 MiB
```

All three must boot to `luit$` and pass `usertests` and `forktest`. Nothing in
the kernel is recompiled between them. That is the entire point: the kernel asks
the device tree what machine it is on. A student kernel that only works at
`-smp 4 -m 128M` has hardcoded something, and you should find out what.

---

## 1. How to use this reference tree

**Do not give students the reference kernel.** Give them the skeleton, the
tests, and the header files. This tree is *yours*: it is what you consult when a
student is stuck, and what you diff against when a submission looks suspicious.

The layout:

```
kernel/     the kernel proper
  entry.S     first instructions (L1/L2)
  kernel.ld   memory layout (L2)
  hal.h       THE HAL CONTRACT (L2) — read this first
  fdt.c       device tree parser (L3)      <- the heart of "not a toy"
  printf.c    console printf + panic (L3)
  palloc.c    physical page allocator + refcounts (L4/L11)
  trap.c      trap handling (L5/L12)
  kernelvec.S uservec.S  trap vectors (L5/L12)
  spinlock.c  locks (L8)
  proc.c      processes, scheduler, SMP (L7/L8/L9)
  swtch.S     context switch (L7)
  vm.c        Sv39 paging, COW (L10/L11)
  syscall.c   syscall dispatch (L6)
  exec.c      ELF loader (L12)
  console.c   interrupt-driven console (L3/L5)
  main.c      boot order — read this to see the whole kernel at a glance
hal/qemu_virt/  uart.c plic.c timer.c  — the ONLY files that know MMIO layouts
hal/shakti/     hal/vega/  — empty. L16 fills these in.
user/       luitc + init + sh + usertests + forktest
docs/ABI.md the system call specification
```

Read `kernel/main.c` first. It is the map of the whole system, in boot order.

---

## 2. What "indigenous, not a toy" actually means in the code

Point students at these four things, repeatedly. They are the difference between
this course and a weekend tutorial.

**(a) Nothing is hardcoded.** Search the kernel for a raw MMIO address. You will
not find one outside `hal/`. The UART base, PLIC base, RAM base, RAM size, and
hart count all come from the device tree at run time. Enforce it:

```bash
grep -rnE '0x[0-9a-fA-F]{7,}' kernel/ | grep -v '0x8000000000000000' | grep -v riscv.h
```

Put this in CI. A student who hardcodes `0x10000000` fails L3.

**(b) The HAL is a real boundary.** `hal.h` declares nine functions. Swap
`HAL=qemu_virt` for `HAL=shakti` in the Makefile and *nothing else in the kernel
changes*. That one line is what makes L16 a port instead of a rewrite.

**(c) Memory is lazy and shared.** `fork()` copies no data — it marks pages
read-only, sets `PTE_COW`, and bumps a refcount. The first write faults and
`cow_fault()` does the copy. This is what real kernels do.

**(d) Every page comes back.** `test_no_leak` forks 20 children that each dirty
8 KB, and asserts the free-page count returns *exactly* to baseline. Refcount
bugs have nowhere to hide. This is the single most valuable test in the suite.

---

## 3. Module-by-module: what to teach, and what will go wrong

For each lab: what the student must produce, what to demo, and the bug you should
expect. **The bugs listed are real** — most of them are ones I hit while writing
this reference kernel, and I have left the fixes and the reasoning in the source
comments. Point students at those comments.

### L1 — Toolchain and first boot
Have them produce a kernel that prints their roll number. Show them
`kernel/entry.S` and `kernel.ld`. Make them explain why the load address is
`0x80200000` (OpenSBI jumps there) and why we are already in S-mode.

*Expect:* wrong load address; forgetting `-ffreestanding -nostdlib`.

### L2 — Linker script and the HAL
The deliverable is `hal.h` — an interface, not code. Make them design the nine
signatures themselves and defend them. Add the CI grep from §2(a) now, on day
one, so it constrains every later lab.

*Expect:* forgetting to zero BSS; misaligned stack (RISC-V wants 16-byte).

### L3 — Device tree, UART, printf  ← **the pivotal lab**
This is where the kernel stops being a toy. Read `kernel/fdt.c` with them.

**Two bugs are guaranteed. Both are documented in the source:**

1. **Endianness.** Every 32-bit field in the FDT is big-endian; RISC-V is
   little-endian. Read one without `be32()` and you get garbage that looks
   *almost* plausible.
2. **Property order.** A node's `compatible` does **not** have to appear before
   its `reg`. A parser that sets a "pending" flag on `compatible` and consumes it
   at the next `reg` will silently attach one node's address to a *different*
   device. I hit exactly this: it reported `uart = 0x100000`, `plic = 0`,
   `memory base = 0`. The fix is in `fdt.c`: buffer the properties for the
   current node and resolve them at `FDT_END_NODE`.

Also: a node's `reg` is decoded with its **parent's** `#address-cells`, not its
own. Keep a small depth stack.

**The test that matters:** relocate the UART and boot again. A device-tree-driven
kernel prints normally. A hardcoded kernel prints nothing. That single test is
Tier 1 vs Tier 2.

**Debugging tip you will need:** before the UART driver exists, a `panic()` is
*invisible*, so the kernel just hangs and the student has no idea why. Fix it as
`printf.c` does: fall back to the SBI console until `console_ready` is set. Note
that OpenSBI v1.3 has **deprecated the legacy console** (EID `0x01`) — it
silently does nothing. Use the DBCN extension (EID `0x4442434E`). I lost time to
this; you should not.

### L4 — Physical page allocator
RAM base and size come from `/memory` in the FDT. Reserve the kernel image **and
the FDT blob**.

**The bug you must warn about:** on qemu virt, OpenSBI puts the FDT near the
**top** of RAM (~`0x87e00000`), not the bottom. If a student "reserves" it by
pushing `free_start` past it, they throw away almost all of memory and end up
managing **1 MiB** while wondering why. Skip *over* the FDT's pages; do not skip
*past* them. See the comment in `palloc.c`.

*Test:* allocate to exhaustion, free everything, count must return to baseline.
Then boot with `-m 64M` and `-m 512M`.

### L5 — Traps, timer, PLIC
Walk `kernelvec.S` register by register. Make them explain why `sscratch` exists.

**PLIC gotcha that will eat an hour:** setting the per-hart enable bit is not
enough. You must also set the IRQ **priority** to something greater than zero —
priority 0 means *never fire*. Symptom: timer interrupts work perfectly, console
input does nothing at all. If a student says "my timer works but typing does
nothing," this is the first thing to check.

### L6 — Syscall ABI
**Spec first.** They write `docs/ABI.md` before they write `syscall.c`. Read the
included one with them.

The graded property is hostility-resistance: `test_badptr` passes a kernel
address, a null, and an unmapped address to `write()`. The kernel must return
`-1` and stay alive. A kernel that panics here has failed, no matter how pretty
the rest is. Show them `copyin`/`copyout` in `vm.c` and make them say out loud
why the kernel may never dereference a user pointer.

### L7 / L8 — Processes, context switch, spinlocks
`swtch.S` is nine loads and nine stores. Make them explain why only
callee-saved registers are saved.

**The bug I hit, and it is a beauty — make sure they don't:** do **not** build a
multi-page kernel stack by calling `palloc()` four times. The free list returns
*non-contiguous* pages. The stack then runs off the first page into memory that
is still free, `palloc()` hands that memory to someone else, and the stack
scribbles over it. In my case it handed out a page of the kernel's own page
table, and I got a load page fault at an address that was "definitely mapped."
A kernel stack must be **contiguous** — carve it from BSS (see `proc.c`).

For spinlocks: interrupts **must** be off while holding one, or a timer interrupt
whose handler takes the same lock deadlocks the hart against itself.

### L9 — SMP
Hart count from `/cpus`. Start secondaries with the SBI HSM extension. `tp` holds
the hart id. Every global they own is now a race.

*Test:* `-smp 1`, `-smp 2`, `-smp 8` must all boot and pass. Watch for a student
whose "lock" was never atomic and who got away with it on one hart.

### L10 / L11 — Sv39, demand paging, COW
Design decision students must be able to defend: **we map the kernel into every
process page table** (Linux-style), so user VAs live low (0–2 GiB) and kernel
VAs live high. Because they never collide, a user page table simply borrows the
kernel's top-level entries (index ≥ 2). Kernel pages have no `PTE_U`, so the MMU
enforces isolation for us. **We therefore need no trampoline page and no `satp`
switch on trap** — unlike xv6. The cost is a 2 GiB cap on user address space. We
accept it, and we say so out loud. Ask them for this trade-off in viva.

Enforce W^X: kernel text is mapped `R|X`, never writable. There is a hidden test.

Insist on `sfence.vma` after *every* page-table change, including in the parent
after `uvmcopy` marks its pages read-only. A missing fence gives you a kernel
that works until it doesn't.

### L12 — ELF loader and user mode
Two graded properties: (1) `p_memsz > p_filesz` means the difference is the
program's `.bss` and **must be zeroed**; (2) a non-executable segment must not be
mapped `X`. A malformed ELF must be *rejected*, not run.

**The bug I hit:** if you forget `user/crt0.S`, the linker cannot find `_start`,
silently defaults the entry point to the first byte of `.text`, and your program
begins executing *in the middle of whatever function landed there*. My
`usertests` "started" inside `ok()` and faulted dereferencing address `1`. If a
student's user program crashes immediately at a nonsense address, check the ELF
entry point first: `riscv64-unknown-elf-readelf -h user/prog`.

### L13–L15 — Block driver, LuitFS, journalling
Not in this reference tree — that is deliberate. These are the labs where the
students earn Tier 3, and `exec.c` is written so that **only `lookup_binary()`
changes**: today it finds an ELF in a table linked into the kernel image; at L14
it does a LuitFS path lookup. The rest of `exec.c` is untouched. Show them that.

For L15, the entire guarantee lives in the **write order**: log blocks → commit
record → install → clear. Make them justify each ordering, and what breaks if
you swap any two. There is no way to fake this one, which is why it is the most
valuable test in the course.

### L16 — SHAKTI / VEGA / FPGA
`hal/shakti/` and `hal/vega/` are empty directories in this tree, on purpose.
If L2 was done honestly, filling them is a few hundred lines. If it was not, this
is where the student finds out. **Any change they must make outside `hal/` is a
design failure they must report and explain** — and that report is worth more
pedagogically than a clean port.

---

## 4. Grading: what to actually do in the lab

Per student, per lab, in about five minutes:

1. **Run the tests.** `make && make qemu`, then `usertests`. Correctness is
   objective; do not argue about it.
2. **Run the adaptivity configs.** `NCPU=1 MEM=64M` and `NCPU=8 MEM=512M`. This
   catches hardcoding faster than reading any code.
3. **Grep for hardcoded MMIO** outside `hal/`.
4. **Pick one file at random and ask them to explain a function.** Then: "set a
   breakpoint here in GDB and tell me what `satp` will be." Three minutes.
5. **Cross-read `LLM_LOG.md` against the diff.** If the log says "wrote this
   myself" and the viva says otherwise, that is the conversation to have.

Use `make qemu-gdb` (port 1234) plus `gdb-multiarch kernel.elf` →
`target remote :1234`. Practise walking a page table in GDB before you ask a
student to.

**A submission that passes every test but cannot be explained is not a pass.**
Both halves are graded. Say so in week 1 and mean it.

---

## 5. The five questions students will ask, and your answers

**"Why not just hardcode the UART address? It works."**
It works on one machine. The moment you touch a SHAKTI board it stops working,
and you will not know why. Hardcoding is the thing that makes a kernel a toy.

**"Why is my kernel silently hanging?"**
Almost always a panic before the console exists. Add the SBI fallback.

**"My timer works but I can't type."**
PLIC priority is 0. Set it to 1.

**"It works with `-smp 1` but breaks with `-smp 4`."**
Your lock isn't a lock, or you have per-CPU state in a global.

**"It worked yesterday."**
You have a missing `sfence.vma` or a refcount leak. Run `test_no_leak`.

---

## 6. Honest limits of this reference kernel

State these plainly; do not oversell it to students.

- **It is verified under QEMU only.** I could not boot it on physical SHAKTI or
  VEGA hardware from here. The HAL is structured for the port and the port is
  L16's job, but the claim "boots on Indian silicon" is not yet *demonstrated* —
  it is *designed for*. Do not let anyone, including yourself, blur that line.
- **L13–L15 (virtio-blk, LuitFS, journalling) are not implemented here.** The
  file system today is a table of ELF binaries linked into the kernel image.
  Persistence is exactly the work the students have to do, and the seam
  (`lookup_binary()`) is deliberately left clean for them.
- **Roughly 2,500 lines.** Single-threaded processes, no networking, no
  multi-user security, 2 GiB user address-space cap. Each of those is a
  *documented decision*, not an accident — and a student must be able to defend
  it, not just recite it.
