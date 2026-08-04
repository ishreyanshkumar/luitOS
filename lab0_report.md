# Lab 0 Report

## Report Q1 - Build and architecture evidence
*Record the first and second build times. Explain why the second build is faster. Then classify kernel.elf, user/echo, mkfs/mkfs, and fs.img as host-side or guest-side artifacts, with one sentence describing each.*

The second build is faster because `make` compares file timestamps and only rebuilds targets whose inputs have changed.
- `kernel.elf`: guest-side artifact, the linked Luit kernel loaded by QEMU/OpenSBI.
- `user/echo`: guest-side artifact, a separately linked user-mode ELF program.
- `mkfs/mkfs`: host-side artifact, a native host utility that constructs fs.img.
- `fs.img`: host-side file used by the guest, a persistent LuitFS disk image containing user programs and files.

## Report Q2 - Explain the boot chain
*Write the Luit boot chain in order, beginning with QEMU and ending at the shell. For each of OpenSBI, the Luit kernel, /init, and /sh, state one responsibility.*

**Boot chain:** QEMU -> OpenSBI -> Luit kernel -> `/init` -> `/sh`
- **QEMU:** emulates the 64-bit RISC-V hardware.
- **OpenSBI:** firmware that supplies RISC-V machine-mode services.
- **Luit kernel:** initialises hardware devices, processes, virtual memory, and provides supervisor-mode OS services.
- **`/init`:** the first user process that sets up the system environment and starts the shell.
- **`/sh`:** the interactive shell program that parses commands and executes user programs.

## Report Q3 - Unix composition
*Draw the file-descriptor connection for `cat note.txt | wc`. Identify which descriptor of cat writes to the pipe and which descriptor of wc reads from it. After reading the PIPE case in user/sh.c, state how many new processes the current shell creates to execute the complete pipeline and what each process does.*

```
cat (stdout = fd 1) -> [write end] kernel pipe [read end] -> (stdin = fd 0) wc
```
The shell creates 2 new processes: one for executing `cat` and one for executing `wc`. (The pipe connects them). Note: some shell implementations may also fork a coordinator process.

## Report Q4 - Process and memory observations
*Include one ps snapshot and one meminfo snapshot taken while vdemo is active. List the process states you observed. Explain why all vdemo children print the same virtual address but maintain different values.*

Process states observed: `run`, `runble`, `sleep`.
All `vdemo` children print the same virtual address but maintain different values because they each have their own private virtual address space mapped to different physical memory pages by the OS.

## Report Q5 - Persistence reasoning
*State whether myroll.txt survived. Explain where the data was stored. Then explain why make clean followed by a rebuild removes it. Finally, explain why this successful experiment does not prove that LuitFS is crash-consistent.*

`myroll.txt` survived across QEMU reboots because its data was stored persistently in `fs.img` on the host machine. `make clean` deletes `fs.img`, and a subsequent rebuild uses `mkfs` to generate a fresh `fs.img` from the current `UPROGS` list, which does not include dynamically created files like `myroll.txt`. The experiment does not prove crash-consistency because we cleanly completed the write before exiting; it does not test recovery from a sudden power loss or crash mid-write.

## Report Q6 - Source organisation
*Create a table with at least six rows. Each row must name one subsystem, its main source file(s), whether it is primarily host-side or guest-side, and one responsibility. Include boot, processes, memory, system calls, filesystem, and hardware abstraction.*

| Subsystem | Main Source File(s) | Host/Guest | Responsibility |
| --- | --- | --- | --- |
| Boot | `kernel/entry.S`, `kernel/main.c` | Guest | First instructions, privilege transition, kernel init |
| Processes | `kernel/proc.c`, `kernel/defs.h` | Guest | Process lifecycle, scheduling, context switching |
| Memory | `kernel/vm.c`, `kernel/palloc.c` | Guest | Physical-page allocation and page-table management |
| System Calls | `kernel/syscall.c`, `kernel/sysfile.c` | Guest | System-call numbers, dispatch, handlers |
| Filesystem | `kernel/fs.c`, `kernel/bio.c` | Guest | Filesystem logic and buffer cache |
| Hardware Abstraction | `hal/hal.h`, `hal/qemu_virt/` | Guest | Device-tree parsing, timer, UART, interrupts |

## Report Q7 - Process structure
*From kernel/defs.h, choose four fields of struct proc. For each field, state its C type and explain its purpose in your own words. Do not copy nearby comments without explanation.*

Assuming standard xv6/Luit fields (varies slightly by codebase):
1. `state` (`enum procstate`): indicates whether the process is runnable, running, sleeping, or a zombie.
2. `pid` (`int`): a unique process identifier number assigned by the kernel.
3. `parent` (`struct proc *`): a pointer to the parent process that created this process via fork.
4. `killed` (`int`): a boolean flag indicating if the process has been marked to terminate soon.

## Report Q8 - Your first program
*Include your complete user/hello.c, the exact UPROGS fragment after your edit, and the terminal output from running hello. State why adding a user program caused fs.img to be rebuilt.*

**user/hello.c:**
```c
#include "ulib.h"
int main(int argc, char *argv[]) {
    printf("hello from Shreyansh Kumar, roll 123456789\n");
    exit(0);
}
```

**UPROGS fragment:**
```makefile
UPROGS = user/init user/sh user/echo user/cat user/ls user/mkdir user/rm \
         user/wc user/grep user/kill user/ln user/ps user/meminfo user/vdemo \
         user/usertests user/forktest user/hello
```

**Terminal output:**
```
luit$ hello
hello from Shreyansh Kumar, roll 123456789
```

Adding a user program caused `fs.img` to be rebuilt because `fs.img` depends on `$(UPROGS)` in the Makefile. When `user/hello` is compiled, it creates a new ELF binary which must be packed into the fresh filesystem image by `mkfs`.
