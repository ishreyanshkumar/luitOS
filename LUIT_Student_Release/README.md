# BrahmaputraOS — LUIT Kernel

A small Unix-like operating system for 64-bit RISC-V, used in CS3106L at IIT Guwahati.

## Start here

Read `docs/lab00/LUIT_Lab00_First_Boot.pdf`, then run:

```bash
make clean
make
make qemu CPUS=1
```

Quit QEMU with `Ctrl-A`, release the keys, then press `X`.

## Source organisation

| Path | Purpose |
|---|---|
| `kernel/` | processes, virtual memory, traps, system calls and LuitFS |
| `hal/qemu_virt/` | QEMU-board UART, timer, interrupt-controller and block-device code |
| `user/` | shell, utilities and regression programs |
| `mkfs/` | host utility that creates the LuitFS disk image |
| `tools/` | build-time source generators |
| `docs/` | technical documentation and Lab 0 |

This archive contains no repository history, instructor files, lab solutions,
grading scripts, hidden tests, or Labs 1–12.
