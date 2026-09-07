# BrahmaputraOS — kernel *Luit*

A small, indigenous, Unix-like teaching operating system for 64-bit RISC-V.

**CS3106L — Operating Systems: Concepts and Construction**
Dr. Satyajit Das · Department of Computer Science and Engineering
Indian Institute of Technology Guwahati

---

This is **Luit Teaching Base v1.0** (tag `base-v1.0`): a complete, bootable
operating system that students receive on day one and extend through twelve
laboratory exercises. It boots on multiple harts, discovers its hardware from
the device tree, mounts a persistent filesystem, and runs a shell with pipes
and redirection — before a student writes a line.

## Quick start

    make            # build the kernel and the disk image
    make qemu       # boot it (Ctrl-A then X to quit)
    make grade      # run the 9 public verification tests

## What's here

| Path | Contents |
|------|----------|
| `kernel/` | the kernel: memory, traps, processes, LuitFS |
| `hal/` | hardware backends: `qemu_virt` (working), `shakti`/`vega` (honest stubs) |
| `user/` | 15 user programs incl. the shell, utilities, and `vdemo` |
| `mkfs/` | host tool that builds the LuitFS disk image |
| `tests/` | the public autograder (`grade.py`) |
| `docs/` | ABI, LuitFS format, debugging war stories, LLM policy, course ops |
| `docs/labs/` | the twelve laboratory specifications |
| `docs/demos/` | classroom demonstrations (start with `virtualization.md`) |
| `staff/` | reference solutions and patches — **not for students** |

## Documentation

* **The book** — *BrahmaputraOS: a Commentary and Guide*, the full commentary
  on this kernel, written to be read with the source open beside it.
* `docs/labs/lab01.md` … `lab12.md` — the laboratory sequence.
* `docs/DEBUGGING.md` — the seven real bugs met while building this kernel,
  preserved as teaching material.

## Verification status

Warning-clean build; boots at 1/2/4 harts; 16/16 usertests at every hart
count; 9/9 public grade tests including power-off persistence; SHAKTI and
VEGA hardware backends cross-compile in CI on every push.
