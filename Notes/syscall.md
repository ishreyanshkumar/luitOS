# System Call Entry & Exit in Luit — Full Walkthrough

> **A note on scope before you read this:** the original lecture deck starts the story _at the moment `ecall` executes_. It does not show the code for process creation, physical memory allocation, or the very first time `sscratch`/`satp`/`kernel_sp` get populated. Those questions are exactly the "no gaps" questions you asked, so I've filled them in below using the conventions that Luit's own slides say it inherited from **xv6** (Luit is explicitly built as an xv6-family kernel — same trapframe offsets, same overall structure, minus the trampoline). Anywhere I'm extending beyond what the slides literally show, I've marked it **[inferred — standard xv6-family convention]** so you know which parts are "verified against the deck" and which parts are "how this kind of kernel necessarily has to work." This keeps the walkthrough gap-free without pretending every line came from the PDF.

---

## Part 0 — What problem are we solving?

A process runs in **user mode**: restricted, sandboxed, cannot touch hardware or other processes' memory directly. The **kernel** runs in **supervisor mode (S-mode)**: unrestricted. A system call is the disciplined, controlled way a user process asks the kernel to temporarily take over, do privileged work, and hand control back — with the process resuming _exactly_ where it left off, as if the trip into the kernel never happened.

Everything in this document is the machinery that makes that illusion possible.

---

## Part 1 — The building blocks

### 1.1 Supervisor CSRs (control/status registers)

Only readable/writable in S-mode:

| Register   | Meaning                                                                                                   |
| ---------- | --------------------------------------------------------------------------------------------------------- |
| `satp`     | Physical address of **this process's** page-table root                                                    |
| `stvec`    | Address the CPU jumps to automatically on any trap                                                        |
| `sepc`     | The user PC at the moment of the trap — **set automatically by hardware**                                 |
| `sscratch` | One scratch slot; Luit parks `&p->tf` (address of the process's trapframe) here                           |
| `scause`   | Numeric reason for the trap (8 = syscall via `ecall`, 13/15 = page faults, …)                             |
| `sstatus`  | Bit-flags: current privilege mode, previous privilege mode (`SPP`), interrupt-enable bits (`SIE`, `SPIE`) |

Instructions: `csrr`/`csrw`/`csrrw` (read/write/atomic-swap a CSR), `sret` (return from trap).

### 1.2 The RISC-V calling convention (ABI)

| Registers    | Name      | Role                    | Preserved by |
| ------------ | --------- | ----------------------- | ------------ |
| x1           | ra        | return address          | caller       |
| x2           | sp        | stack pointer           | callee       |
| x8/x9        | s0/fp, s1 | saved                   | callee       |
| x10–11       | a0–a1     | args / **return value** | caller       |
| x12–17       | a2–a7     | more args               | caller       |
| x18–27       | s2–s11    | saved                   | callee       |
| x5–7, x28–31 | t0–t6     | temporaries             | caller       |

**The one fact that drives this entire lecture:** `a7` carries the **syscall number**, `a0`–`a5` carry arguments, `a0` carries the **return value**. Because the ABI already places arguments in `a0..a5` before the syscall wrapper even runs, the wrapper only has to set `a7` and trap.

---

## Part 2 — Process creation: where all this state first comes from

_(This section is the "no gaps" fill-in. Luit's slides don't show this code, but this is what must happen before a process can ever hit `ecall` at all — using standard xv6-family conventions.)_ **[inferred]**

### 2.1 The process table and `kalloc()` — the free list

The kernel keeps a fixed-size array of `struct proc` slots (not dynamically allocated — it's static kernel memory, sized at compile/boot time). Creating a process (`allocproc()`-style function) means:

1. **Scan the proc table** for a slot marked `UNUSED`, claim it.
2. Ask the **physical page allocator** for memory. This allocator (`kalloc()`/`kfree()`) is built at boot by walking all free physical RAM (as discovered from the device tree, per Luit's "discovered, not hardcoded hardware" philosophy) and threading every free 4KB page into a **linked free list**. `kalloc()` pops one page off the head of that list; `kfree()` pushes a page back on. This is the literal "free list" you're asking about — it's a **physical page allocator**, not something specific to trapframes or stacks; trapframes, kernel stacks, and page-table pages are just three different _consumers_ of the same free-page pool.

### 2.2 Allocating the trapframe

```
p->tf = (struct trapframe *) kalloc();   // one physical page, popped off the free list
```

This page becomes `struct trapframe`. At this point every field in it is garbage/zero until filled in below.

### 2.3 Allocating the kernel stack

```
char *kstack_page = kalloc();            // another page off the free list
p->tf->kernel_sp = (uint64)kstack_page + PGSIZE;   // stacks grow DOWN, so store the TOP
```

`kernel_sp` is stored as the **top** of the page because RISC-V (like almost all architectures) grows the stack downward — the first thing pushed goes at the highest address.

This is the value `uservec.S` later does `ld sp, 8(a0)` to fetch — so now you can see exactly where that number came from: it's not computed at trap time, it was decided once, at process-creation time, and just sits in the trapframe waiting to be reloaded on every single trap this process ever takes.

### 2.4 Allocating the page table — and here's the `satp` clarification you asked about

> You assumed _"satp is common for all processes so kernel space is shared, obviously."_ This is half right and worth being precise about, because it's exactly where the `kernel_satp` question comes from too.

- **`satp` is _not_ the same value for every process.** `satp` holds the physical address of the **root page-table page**, and every process gets its **own, separate page table**, built by a `proc_pagetable()`-style function that also calls `kalloc()` for the table's internal pages. This is necessary because each process has different user-space mappings (its own code, stack, heap sit at different physical pages).
- **What _is_ shared is the _content_ of the kernel-mapping portion of every one of those page tables.** When Luit builds a fresh process's page table, it copies in the _same set of PTEs_ (pointing at the _same physical kernel pages_, no `PTE_U` bit) that every other process's page table also has. So: different `satp` values (different root pages), but an identical sub-tree of mappings baked into each one. That identical sub-tree is what lets the kernel run correctly no matter which process's page table happens to be currently active — which is _exactly_ the property that lets Luit skip switching `satp` on trap entry.
- Physical memory that the kernel itself allocates for its own bookkeeping (trapframe pages, kernel stack pages, page-table pages) is reachable through this shared kernel-mapped region too — typically because Luit maps all of physical RAM 1:1 (identity-mapped) in that kernel region, so any page `kalloc()` hands out is automatically visible to kernel code, in every process's page table, with no extra per-process mapping step required.

### 2.5 So then, why does the trapframe even _have_ a `kernel_satp` field?

The slides say it plainly: _"`kernel_satp` is still stored at offset 0, but `uservec` never loads it: we don't switch page tables on entry. `usertrapret` refreshes it for bookkeeping."_

Reasoning this out fully:

- On the **fast path** (user syscall in → `uservec` → `usertrap` → `syscall` → `usertrapret` → `userret` → back to user), `kernel_satp` is genuinely dead weight — never read, only written.
- It exists because Luit's trapframe layout deliberately keeps the **same struct offsets as xv6** ("so tooling and muscle memory carry over"), and xv6 _does_ need this field, because xv6 _does_ switch `satp` on every trap (that's the whole trampoline story). Luit inherited the field structurally without inheriting the need.
- The field is refreshed (`p->tf->kernel_satp = r_satp();`) on every return anyway — a cheap, harmless bit of bookkeeping — most plausibly so that **other kernel code paths that are _not_ the fast trap path** (e.g. the scheduler switching between processes, or any future code that needs to know/restore "the pure kernel address space" when no user process is current) always has an up-to-date, correct value available if it's ever needed. **[inferred — the slides don't name a specific consumer, but this is the standard reason such a field is kept around in this kernel family.]**

So: `satp` ≠ `kernel_satp` conceptually. `satp` is _whichever process's_ root page table happens to be currently loaded (and Luit deliberately never changes it during a trap). `kernel_satp` is a _record of what the kernel's-eye-view satp value looks like_, kept for bookkeeping/compatibility, not consulted by the entry/exit fast path.

### 2.6 Populating `sscratch`

`sscratch` must hold `&p->tf` **before** this process is ever allowed to run in user mode for the first time — otherwise the very first `ecall` it makes would have nothing to swap into `a0` in `uservec.S`'s opening `csrrw`. Given what the slides _do_ show — that `usertrapret()` re-freshens several trapframe-adjacent fields right before every return to the user — the natural and consistent place for `sscratch` to be (re)armed is **inside that same `usertrapret()` "refresh" step, right before the final `sret`/`userret` hand-off**, so it's correctly loaded both the _first_ time a brand-new process is launched into user mode and every subsequent time it returns after a trap. **[inferred placement — the exact line isn't shown in the deck excerpt, but this is the only point in the shown code that is guaranteed to run before every single entry into user mode.]**

### 2.7 Summary of process-creation-time setup

| Field                                   | Set from                                                                                                                                                        | When                                                                                  |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `p->tf`                                 | `kalloc()` — pops a page off the physical free list                                                                                                             | process creation                                                                      |
| `tf->kernel_sp`                         | top address of a separately `kalloc()`'d page                                                                                                                   | process creation                                                                      |
| `tf->kernel_trap`                       | address of `usertrap()` (a fixed, known kernel symbol)                                                                                                          | process creation                                                                      |
| `satp` (the process's own)              | root of a freshly built page table via `proc_pagetable()`, itself built from `kalloc()`'d pages, pre-populated with the shared kernel PTEs                      | process creation                                                                      |
| `tf->kernel_satp`                       | `r_satp()` — copied from the live CSR                                                                                                                           | refreshed every return (`usertrapret`), harmless bookkeeping                          |
| `sscratch`                              | `&p->tf`                                                                                                                                                        | armed every time before control is handed to the user (first launch and every return) |
| `tf->epc`, and all 31 general registers | whatever the user program's initial entry state is (for a brand-new process) or whatever was live at the moment of the _previous_ trap (for a resuming process) | process creation (once) / every trap (thereafter)                                     |

With all of that in place, the process can now safely execute `ecall` for the very first time — which is where the original lecture picks up.

---

## Part 3 — The core design decision: Luit vs xv6

|                                              | xv6                                                                                                                                             | Luit                                                                                                                                                                                     |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Is the kernel mapped in the user page table? | **No**                                                                                                                                          | **Yes** (like Linux), but without `PTE_U`, so user code still faults if it tries to touch it                                                                                             |
| Consequence                                  | Must switch `satp` on every trap; the switching code must live at an identical virtual address in every address space → the **trampoline page** | `stvec` can point straight at `uservec`'s real address — no trampoline needed                                                                                                            |
| What changes on trap entry                   | page table **and** stack                                                                                                                        | **only the stack**                                                                                                                                                                       |
| Cost                                         | page-table switch + `sfence.vma` on every syscall                                                                                               | none of that — simpler, faster                                                                                                                                                           |
| Trade-off                                    | isolation via strict non-mapping                                                                                                                | kernel mappings live in every address space — this is the exact shape Meltdown-style speculative attacks exploited, which is why production kernels added **KPTI** on top of this design |

Straight from `kernel/vm.c`: _"...avoid switching page tables on every trap (which is what xv6 does, and why xv6 needs a trampoline page)."_

**This is the idea the rest of the document keeps returning to: Luit swaps the stack, not the page table.**

---

## Part 4 — The trapframe: where user state goes to hide

```c
struct trapframe {
/* 0 */   uint64 kernel_satp;    // bookkeeping copy of satp (see Part 2.5) — NOT used by uservec
/* 8 */   uint64 kernel_sp;      // top of this process's kernel stack (see Part 2.3)
/* 16*/   uint64 kernel_trap;    // address of usertrap()
/* 24*/   uint64 epc;            // user's PC at the moment of ecall
/* 32*/   uint64 kernel_hartid;  // which CPU core
/* 40*/   uint64 ra, sp, gp, tp;
/* 72*/   uint64 t0, t1, t2;
/* 96*/   uint64 s0, s1;
/*112*/   uint64 a0,a1,a2,a3,a4,a5,a6,a7;   // offset 168 = a7 = syscall number
/*176*/   uint64 s2..s11;
/*256*/   uint64 t3, t4, t5, t6;
};
```

One page per process, always reachable by the kernel (it lives in the shared, identity-mapped kernel region — see Part 2.4). `sscratch` always points at the _current_ process's copy. Think of it as a labeled parking lot: one numbered space per register, plus a handful of extra slots the kernel pre-fills at process-creation time (Part 2) so that the instant a trap fires, every value `uservec.S` needs is already sitting there waiting — no searching, no computing.

---

## Part 5 — The full trace: a user `write()` call

### Step 1 — `usys.S`: the generated user-side stub

Generated from a table by `tools/gensyscalls.py`:

```
# kernel/syscall.tbl
13 sleep sys_sleep
16 write sys_write
```

```asm
.macro SYSCALL name, num
.globl \name
\name:
    li  a7, \num     ; a7 = syscall number
    ecall            ; trap into the kernel
    ret              ; return to caller once kernel is done
.endm

SYSCALL write, 16     ; → li a7,16 ; ecall ; ret
```

- `li a7, 16` — load the literal syscall number for `write` into `a7`. Nothing else needs setting up: the arguments `fd, buf, count` are **already** in `a0, a1, a2`, placed there by ordinary compiled code before this stub was even called — that's just the normal C calling convention at work, unrelated to syscalls specifically.
- `ecall` — the trap instruction (full breakdown next).
- `ret` — once control returns here after the kernel is done, jump back via `ra`, exactly like any ordinary function return. The caller of `write()` never knows a privilege change happened.

**Versioning note:** the table has a rule enforced at build time — renumbering an existing entry is an ABI break (must bump `docs/ABI.md`); adding new numbers is fine. xv6's equivalent (`usys.pl`) has no such rule.

### Step 1b — What `ecall` actually does, in hardware, atomically

This is also **exactly where privilege gets raised** — there is no separate assembly instruction for it; it's a side effect of executing `ecall` itself, performed by the CPU before any software runs:

1. **Copies the current privilege mode into the `SPP` bit of `sstatus`** — i.e. hardware records "we came from user mode" so `sret` can later restore it correctly.
2. **Raises the privilege level to S-mode.** _(This is the actual privilege-raise you asked about — it happens inside the `ecall` instruction's hardware execution, not in any line of assembly you can point to.)_
3. **Copies the current interrupt-enable bit (`SIE`) into `SPIE`, then clears `SIE`** — interrupts are disabled during the most delicate part of trap entry, until software explicitly re-enables them later (`intr_on()` in `usertrap()`).
4. **Latches the current PC (the address of the `ecall` instruction) into `sepc`.**
5. **Sets `scause`** to the reason code (8, for "ecall from user mode").
6. **Jumps to whatever address `stvec` holds** — in Luit, `stvec` is already `uservec`'s real kernel address (no trampoline, per Part 3).

That's _all_ hardware does. It does **not** save general-purpose registers, does **not** switch the stack, does **not** touch `satp`. Everything else is software's job — a deliberate RISC-V design philosophy: minimal hardware, maximal software control.

### Step 2 — `uservec.S`: save state, switch the stack

Entering here: we are now in S-mode (hardware just did that), but every general register still holds **user** values, and `sp` is still the **user's stack pointer**. `sscratch` holds `&p->tf` (armed back in Part 2.6).

```asm
uservec:
    csrrw a0, sscratch, a0
```

Atomic swap: reads `sscratch` (the trapframe address) into `a0`, _and simultaneously_ writes the user's old `a0` into `sscratch`. We need a spare register to work with, but every register currently belongs to the user — this instruction lets us borrow `a0` while safely parking its original value in `sscratch` so nothing is lost.

```asm
    sd ra, 40(a0)
    ...                 ; gp, tp, t0-t6, s0-s11, a1-a7, t3-t6
    sd t6, 280(a0)
```

`sd` = store doubleword (8 bytes). `a0` currently holds the trapframe's address, so `40(a0)` is "40 bytes past the trapframe's start" — exactly the `ra` field from Part 4's layout. Repeated mechanically for every register except the `a0` we're mid-juggling.

```asm
    csrr t0, sscratch   ; recover the user's ORIGINAL a0 from where we parked it
    sd   t0, 112(a0)    ; tf->a0
```

Now all 31+ registers have a safe copy in memory.

```asm
    csrr t1, sepc       ; where ecall was
    sd   t1, 24(a0)     ; tf->epc
```

Hardware auto-saved this into `sepc` back in Step 1b's action 4; here it's additionally copied into the trapframe so it survives even if `sepc` gets clobbered by something later.

```asm
    ld tp, 32(a0)       ; hartid, pre-filled at process creation
    ld sp, 8(a0)        ; ← THE STACK SWITCH: sp = kernel_sp (Part 2.3)
    ld t1, 16(a0)       ; kernel_trap = &usertrap (Part 2.7)
    jr t1                ; jump into kernel C — no satp touched, no trampoline
```

The only switch happening here is the stack pointer, loaded from the value that was decided once, back at process-creation time. **No `csrw satp` anywhere** — that absence, compared to xv6, _is_ the whole design decision made concrete in code.

### Step 3 — `usertrap()`: why did we trap?

Now running kernel C, on the kernel stack, all user state safely parked.

```c
void usertrap(void) {
  if (r_sstatus() & SSTATUS_SPP)
    panic("came from S-mode");
```

`SPP` was set by hardware in Step 1b action 1. If it says the trap came from S-mode, that's impossible for a legitimate user trap — a bug or attack. This is a one-line isolation tripwire.

```c
  w_stvec((uint64)kernelvec);
```

We just arrived via the user-trap path. While _inside_ the kernel, if something else traps (a bug causing a fault mid-kernel-execution), it should go to a different handler meant for kernel-originated traps — not loop back through user-trap logic.

```c
  struct proc *p = myproc();
  p->tf->epc = r_sepc();
```

Re-save `sepc` into the trapframe explicitly in C (belt-and-suspenders alongside `uservec.S`'s copy).

```c
  uint64 scause = r_scause();
```

Read the hardware-set reason code from Step 1b action 5.

```c
  if (scause == 8) {                 // ecall from user
    if (p->killed) exit(-1);
    p->tf->epc += 4;
    intr_on();
    syscall();
```

`scause == 8` = syscall. If the process is already marked for death, don't bother continuing.

`epc += 4`: RISC-V instructions here are 4 bytes; `sepc` currently points _at_ the `ecall` instruction. Without this bump, resuming later would re-execute `ecall` forever. Advancing by 4 makes resumption land on the instruction right after `ecall` — which, per `usys.S`, is `ret`.

`intr_on()`: interrupts were disabled by hardware in Step 1b action 3; now that the fragile part of entry is done, they're safely re-enabled.

`syscall()`: the dispatch (Step 4).

```c
  } else if (scause==15 || scause==13) {
    // page fault hook — later labs (COW / mmap)
  } else {
    devintr(); ...
  }
  usertrapret();
}
```

Non-syscall traps branch elsewhere (page faults reserved for future labs; device interrupts handled by `devintr()`). Every path converges on `usertrapret()`.

A small helper, `cause_str()`, exists purely to turn numeric `scause` values into readable strings (`2`→illegal instruction, `8`→ecall, `12/13/15`→page fault variants) for panic/kill messages.

### Step 4 — `syscall()`: dispatch table

```c
void syscall(void) {
  struct proc *p = myproc();
  uint64 num = p->tf->a7;
```

`a7` has held the syscall number since `usys.S`'s `li a7, 16`; `uservec.S` copied it into the trapframe; now it's finally read back.

```c
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    p->tf->a0 = syscalls[num]();
  else
    p->tf->a0 = -1;
}
```

`syscalls[]` is a generated function-pointer table (from the same `syscall.tbl`); `syscalls[16]` is `sys_write`. Because `num` came straight from user-controlled `a7`, it's validated **before** indexing — bounds-checked and checked non-null — since a hostile or buggy program could put any garbage into `a7`, and blindly indexing/calling could jump execution anywhere. Valid → call the handler, store its result into `tf->a0` (the ABI-designated return slot). Invalid → write `-1`, no crash.

`sys_write()` (in `kernel/sysfile.c`) does the real work, using `copyin`/`copyout` to safely move data between user and kernel memory — these also refuse unmapped, kernel-owned, or non-`PTE_U` addresses, for the same "never trust user input" reason.

### Step 5 — the return trip

Back in `usertrap()`, falling through to:

```c
void usertrapret(void) {
  intr_off();
  w_stvec((uint64)uservec);
```

Interrupts off again for this delicate bookkeeping. `stvec` reset to `uservec` — the _next_ trap (whenever it happens) should go through the normal user-trap path again.

```c
  p->tf->kernel_satp = r_satp();
  p->tf->kernel_trap = (uint64)usertrap;
```

Refreshes the bookkeeping fields discussed in Part 2.5/2.7, so they're correct for the _next_ time this process traps.

```c
  x = r_sstatus();
  x &= ~SSTATUS_SPP;   // SPP=0 → tells sret to drop to USER mode
  x |= SSTATUS_SPIE;   // interrupts re-enabled once back in user mode
  w_sstatus(x);
  w_sepc(p->tf->epc);
```

**This is also exactly where privilege-lowering is _prepared_** (the actual lowering itself happens inside `sret`, next). Clearing `SPP` is the instruction that determines what `sret` will do: `SPP=0` means "go to user mode." `sepc` is loaded with the (already `+4`-advanced) saved user PC.

```c
  userret(p->tf);
}
```

```asm
userret:
    ld ra,  40(a0)
    ...                  ; mirror image of uservec's saves
    ld t6, 280(a0)
    ld a0, 112(a0)       ; LAST: overwrite a0 with the syscall's return value
    sret
```

Exact mirror of the save sequence. `a0` is restored **last** on purpose: we needed it as our working pointer into the trapframe (just like at entry), and only once done reading do we finally overwrite it with the syscall's actual return value.

**`sret` is where privilege is actually lowered** — it reads the `SPP` bit (just cleared above) and atomically switches the CPU's privilege mode to whatever `SPP` says (0 = user), then jumps to `sepc`. This is the exact mirror of what `ecall` did to raise privilege in Step 1b — same mechanism, opposite direction, both entirely inside a single hardware instruction.

The user resumes exactly one instruction past its original `ecall` — landing on `ret` in `usys.S` — with the syscall's result already sitting in `a0`, indistinguishable from an ordinary function return.

---

## Part 6 — The complete flow, gap-free, start to finish

```
PROCESS CREATION (once, before this process ever runs)
  allocproc(): claim a free proc-table slot
  p->tf        = kalloc()                      // trapframe page, off the physical free list
  kstack page  = kalloc()                      // separate page, off the same free list
  p->tf->kernel_sp   = kstack_top               // stack grows down → store the TOP
  p->tf->kernel_trap = &usertrap                // fixed kernel symbol
  proc_pagetable(): kalloc() page-table pages, build THIS process's own
                    page table, pre-populate it with the SHARED kernel PTEs
                    (same physical kernel pages in every process's table,
                     just no PTE_U — this is the "kernel space is shared,
                     satp is per-process" clarification)
  satp (this process's) = physical address of that fresh root page table
  sscratch will be armed to &p->tf every time before this process runs
       (both the first launch, and every subsequent return via usertrapret)

────────────────────────────────────────────────────────────────────

user calls write(fd, buf, n)      // a0,a1,a2 already = fd,buf,n (ordinary ABI)
  → usys.S:  li a7,16 ; ecall

     ── ecall (hardware, atomic) ──────────────────────────────
        SPP ← current mode (user)         [remembers where we came from]
        privilege ← S-mode                [★ PRIVILEGE RAISED HERE ★]
        SPIE ← SIE ; SIE ← 0               [interrupts off during entry]
        sepc ← PC of this ecall
        scause ← 8
        PC ← stvec (= uservec, no trampoline)
     ───────────────────────────────────────────────────────────

  → uservec.S:
        csrrw a0, sscratch, a0        // a0 = &tf, user's old a0 parked in sscratch
        save all 31 other regs → tf
        recover parked a0 → tf->a0
        tf->epc ← sepc
        sp ← tf->kernel_sp             // ← ONLY the stack switches, not satp
        jr tf->kernel_trap             // → usertrap()

  → usertrap():
        SPP check (isolation tripwire)
        stvec ← kernelvec              // traps-while-in-kernel go elsewhere now
        scause==8 → tf->epc += 4 (skip past ecall) ; intr_on() ; syscall()

  → syscall():
        num = tf->a7 (=16)
        bounds-check num against syscalls[]
        tf->a0 = syscalls[16]()        // = sys_write(), actually does the work

  → usertrapret():
        intr_off()
        stvec ← uservec                // next trap goes to the normal path again
        tf->kernel_satp ← r_satp()     // bookkeeping refresh only, unused fast-path
        sstatus.SPP ← 0                // ★ prepares privilege LOWER ★
        sstatus.SPIE ← 1
        sepc ← tf->epc
        (sscratch re-armed to &tf, ready for the NEXT trap)

  → userret(tf):
        restore all regs from tf (a0 restored LAST = return value)
        sret

     ── sret (hardware, atomic) ───────────────────────────────
        privilege ← SPP (=0=user)         [★ PRIVILEGE LOWERED HERE ★]
        PC ← sepc
     ───────────────────────────────────────────────────────────

  → back in usys.S at `ret`, a0 = result → write() returns normally to its caller
```

### The two invariants holding it all together

1. **`a7` selects, `a0` returns** — this ABI contract never changes across the boundary.
2. **The page table never changes during a trap** — only the stack pointer and privilege level move. That is Luit's defining simplification versus xv6.

### Where exactly privilege changes (direct answer to "where are the bits raised")

| Event                       | Instruction responsible                                                       | Bit involved                                                                                  |
| --------------------------- | ----------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| **Raise** user → supervisor | `ecall` (hardware, atomic, as a side effect — no explicit software CSR write) | sets current mode to S; records old mode into `sstatus.SPP`                                   |
| **Lower** supervisor → user | `sret` (hardware, atomic)                                                     | reads `sstatus.SPP` (software cleared it to 0 in `usertrapret`) and switches mode accordingly |

Software never directly says "become user mode" or "become supervisor mode" with a CSR write — it only **prepares the `SPP` bit** ahead of time (`usertrapret` clears it), and the actual mode change is a guaranteed side effect of the `ecall`/`sret` instructions themselves.

---

## Part 7 — Security: can a hostile program abuse this door?

- The user fully controls `a7` and argument registers — the kernel treats all of it as **hostile input**: `syscall()` bounds-checks the number before indexing; every pointer argument crosses `copyin`/`copyout`, which refuse anything unmapped, kernel-owned, or lacking `PTE_U`.
- The user **cannot forge entry**: `ecall` alone raises privilege, and it can only land at `stvec` — an address only the kernel controls. The `SSTATUS_SPP` guard in `usertrap()` rejects any trap that didn't genuinely originate in user mode.
- **Honest trade-off:** mapping the kernel into every address space (without `PTE_U`) is safe against _direct_ access, but is exactly the shape that speculative side-channel attacks like Meltdown exploited — hence KPTI in production kernels. For a teaching kernel, this is the right call: you see the mechanism clearly without trampoline complexity, and the trade-off itself becomes the discussion.

---

## One-paragraph summary

A system call is a privilege change wrapped around a register save, a stack switch, and a table dispatch. Before any of it can happen, process creation must pre-allocate a trapframe and kernel stack (both pulled from the kernel's physical free list), build a per-process page table whose kernel region mirrors every other process's, and arm `sscratch`. `ecall` then atomically raises privilege and jumps to `uservec`, which saves all user state into the trapframe and swaps only the stack pointer — never `satp`, because the kernel is already mapped everywhere. `usertrap()` reads `scause`, `syscall()` dispatches on `a7` and writes the result to `a0`, and `usertrapret()`/`userret`/`sret` mirror the entire process in reverse — `sret` atomically lowering privilege back to user mode and resuming exactly one instruction past the original `ecall`, with the answer already waiting in `a0`.
