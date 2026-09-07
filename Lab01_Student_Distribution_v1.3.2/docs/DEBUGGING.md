# Debugging Luit

This document gives the debugging workflow used in Lab 1.

## 1. Two-terminal GDB loop

Terminal A:

```bash
make qemu-gdb CPUS=1
```

QEMU starts paused and listens on TCP port 1234.

Terminal B:

```bash
gdb-multiarch kernel.elf
```

The supplied `.gdbinit` defines:

| Command | Purpose |
|---|---|
| `trapregs` | print `scause`, `sepc`, `stval`, `sstatus`, and `satp` |
| `procs` | print in-use process slots |
| `tf <ptr>` | print saved registers in a trap frame |

If GDB refuses to auto-load `.gdbinit`, follow the safe-path instruction that
GDB prints.

## 2. Useful Lab 1 breakpoints

```gdb
break usertrap
break syscall
break sys_sleep
break usertrapret
```

`usertrap` is reached for every user-mode syscall, fault, and interrupt. Use a
condition or inspect `a7` so you stop on the syscall relevant to your trace.

Useful commands include:

```gdb
print myproc()->pid
print myproc()->name
print/x $a7
print/x $a0
print/x $scause
print/x $sepc
bt
```

## 3. Reading trap information

- `scause` identifies the reason for entering the kernel. An environment call
  from user mode has cause 8.
- `sepc` records the user instruction address at which the trap occurred.
- `stval` supplies additional fault information for exceptions that use it.
- The kernel advances the saved user `epc` past the four-byte `ecall`
  instruction before returning to user mode.

## 4. Multi-hart debugging

Start with one hart while learning the path. For concurrency-related checks,
repeat with four harts.

```gdb
info threads
thread apply all bt
```

Each GDB thread corresponds to a QEMU hart.

## 5. Regression loop

```bash
make clean
make
make lab01-check
make grade
```

Run these checks after implementation changes and before creating the final
submission ZIP.
