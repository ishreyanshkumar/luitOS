# Debugging LUIT

## 1. Two-terminal GDB workflow

Terminal A:

```bash
make qemu-gdb CPUS=1
```

Terminal B:

```bash
gdb-multiarch kernel.elf
```

The supplied `.gdbinit` defines:

| Command | Description |
|---|---|
| `trapregs` | display `scause`, `sepc`, `stval`, `sstatus`, and `satp` |
| `procs` | display active process-table entries |
| `tf <ptr>` | display registers saved in a trap frame |

## 2. Decode an unexpected trap

1. `scause` identifies the event. Common values include instruction, load, and
   store page faults (`12`, `13`, and `15`), illegal instruction (`2`), and a
   user-mode environment call (`8`).
2. `sepc` identifies the faulting instruction. Resolve a kernel address with:

   ```bash
   riscv64-unknown-elf-addr2line -e kernel.elf 0x8020xxxx
   ```

   For a user fault, use the relevant user ELF file.
3. `stval` usually identifies the address involved in the fault.

## 3. Useful breakpoints

```gdb
b usertrap
b syscall
b scheduler
b panic
```

After breaking in `syscall`, useful expressions include:

```gdb
p myproc()->name
p myproc()->pid
tf myproc()->trapframe
```

## 4. Inspect page tables

```gdb
p/x myproc()->pagetable
x/8gx <page-table-address>
```

For an Sv39 PTE, the physical page address is obtained from `(pte >> 10) << 12`.
The kernel uses identity mappings for RAM and a high virtual alias for MMIO.

## 5. Multi-hart debugging

```gdb
info threads
thread 2
thread apply all bt
```

A global backtrace is especially useful for diagnosing lock, wakeup, and
interrupt-related hangs.

## 6. Avoid intrusive logging

Kernel `printf` takes a lock and can alter timing. In interrupt or scheduler
paths, prefer counters inspected later or GDB state inspection.

## 7. Regression checks

After a source change, rebuild from a clean tree and run the in-system programs:

```bash
make clean
make -j
make qemu CPUS=1
```

At the shell prompt, `usertests` and `forktest` exercise the baseline kernel.
Repeat with multiple harts when investigating concurrency.
