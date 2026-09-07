# Debugging Luit

This is the workflow you (student or TA) will use for every lab. Learn it in
Lab 2, before you change any kernel code. Nothing here is optional knowledge.

## 1. The two-terminal GDB loop

Terminal A:

    make qemu-gdb            # QEMU starts frozen, waiting on tcp::1234
    make qemu-gdb CPUS=1     # start with one hart while learning; less noise

Terminal B:

    gdb-multiarch kernel.elf   # picks up .gdbinit automatically

If gdb complains about auto-loading, follow the one-line fix it prints (add
`add-auto-load-safe-path` to your `~/.config/gdb/gdbinit`).

You now have three custom commands, defined in `.gdbinit`:

| Command    | What it shows                                              |
|------------|------------------------------------------------------------|
| `trapregs` | scause / sepc / stval / sstatus / satp                     |
| `procs`    | every in-use process-table slot: pid, state, name          |
| `tf <ptr>` | the saved user registers inside a trap frame               |

## 2. Decoding a crash in under a minute

Every unexpected trap prints scause, sepc and stval before the panic. Use them
in this order:

1. **scause** tells you *what happened*. The ones you will actually see:
   - `12` instruction page fault, `13` load page fault, `15` store page fault
   - `2` illegal instruction, `8` ecall from U-mode (that one is normal)
2. **sepc** tells you *where*. Map it to a line:
       riscv64-unknown-elf-addr2line -e kernel.elf 0x8020xxxx
   For a user-mode fault, use the user program's ELF instead:
       riscv64-unknown-elf-addr2line -e user/sh 0x...
3. **stval** tells you *which address* was touched. `0x0` means a null
   dereference; a huge address usually means a corrupted pointer or a missing
   page-table mapping.

## 3. Breakpoints that earn their keep

    b usertrap        # every syscall, fault and interrupt from user mode
    b syscall         # just syscalls; then `p num` to see which one
    b scheduler       # each hart's idle/dispatch loop
    b panic           # freeze the machine exactly at the failure

After `b syscall`, this inspects the calling process:

    p myproc()->name
    p myproc()->pid
    tf myproc()->trapframe

## 4. Inspecting page tables

Print a PTE walk by hand (Lab 5 automates this with vmprint):

    p/x myproc()->pagetable
    x/8gx <that address>          # top-level entries
    # PTE -> physical address: (pte >> 10) << 12

Remember: after `kvminithart()` the kernel runs on virtual addresses that are
identity-mapped for RAM, and MMIO is re-mapped at `pa + 0x1_0000_0000`.

## 5. Multi-hart debugging

    info threads          # one gdb thread per hart
    thread 2              # switch to hart 1
    thread apply all bt   # backtrace on every hart -- first thing to run on a hang

A hang with no panic is almost always: (a) a lock never released, (b) a
`wakeup()` that nobody was sleeping on yet, or (c) an interrupt that never
fires. `thread apply all bt` distinguishes the three immediately.

## 6. printf debugging without wrecking timing

Kernel `printf` takes a lock. Inside interrupt handlers or the scheduler it can
reorder or deadlock the very bug you are chasing. Prefer:

- incrementing a global counter and printing it later from a syscall,
- `procs` in gdb instead of printf inside `scheduler()`.

## 7. The grading loop

    make grade            # what CI runs; what (part of) your marks run

Run it before every push. It boots at 1, 2 and 4 harts, at 64M–512M RAM, and
drives usertests and forktest through the shell. If it hangs locally it will
hang in CI too — QEMU and toolchain versions are pinned in the Dockerfile.
