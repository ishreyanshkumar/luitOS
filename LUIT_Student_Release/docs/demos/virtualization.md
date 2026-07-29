# Demo: virtualization — "every process thinks it owns the machine"

Luit demonstrates all three classical virtualizations: the CPU, memory, and I/O.

## Setup (before class)

    make
    make qemu CPUS=1

Boot on a SINGLE core (`CPUS=1`) so the CPU time-slicing is unmistakable:
many processes, one processor. You will land at the `luit$` prompt.

**To quit QEMU at any time:** press `Ctrl-A`, release, then press `X`.

---

## Demo 1 — Memory virtualization (the headline)

ONE command. It launches several processes itself, so the demonstration never
depends on how fast you can type:

    vdemo

Optional arguments — `vdemo [processes] [rounds]`, e.g. `vdemo 5 3`:

    vdemo 5           # five processes instead of three
    vdemo 4 10        # four processes, ten rounds each (runs longer)

Expected output:

    === virtualization demo: 3 processes, one machine ===
    watch the ADDRESS (identical everywhere) and the VALUE (private to each)

    pid 4: &owned_by_me = 0x1b38   value = 4
    pid 5: &owned_by_me = 0x1b38   value = 5
    pid 6: &owned_by_me = 0x1b38   value = 6
    pid 4: &owned_by_me = 0x1b38   value = 1004
    pid 5: &owned_by_me = 0x1b38   value = 1005
    pid 6: &owned_by_me = 0x1b38   value = 1006
    ...
    pid 4: finished with 6004  (nobody else could touch it)
    pid 5: finished with 6005  (nobody else could touch it)
    pid 6: finished with 6006  (nobody else could touch it)

**The teaching point:** every process prints the IDENTICAL address
(`0x1b38`), yet each holds a value no other process can touch. The address is
*virtual*; the physical memory behind it is *private*.

**Question to pose the class:** "If they really shared memory, what value
would they all print at the end?" (Answer: the same one — last writer wins.)
The fact that they DIFFER is the proof of isolation.

## Demo 2 — CPU virtualization (same run, no extra work)

Point at the output you already have: the lines are INTERLEAVED — pid 4, 5, 6
taking turns — even though you booted with **one** core. Each process runs as
if it owned the CPU continuously; in reality the scheduler is slicing one
processor among them.

To see the process table live, run a longer job in the background and inspect:

    vdemo 3 40 &
    ps

`ps` shows several processes coexisting in `run` / `runble` / `sleep` states,
none aware the others exist. Run `ps` a few times to watch states change.

> **Note on `&`:** background jobs work correctly — the `luit$` prompt returns
> immediately. But type ONE command per line: Luit's shell accepts a single
> trailing `&` (`vdemo &`), not several chained on one line
> (`vdemo & vdemo & vdemo` is a syntax error). If you launch two jobs by hand,
> give the first a long run (`vdemo 3 40 &`) so it is still alive when you
> finish typing the second.

## Demo 3 — File-descriptor virtualization

    echo hello
    echo hello > greeting
    cat greeting

The same `echo` program, using the same descriptor 1 — the console the first
time, a file the second — with no change to `echo` itself. Its private fd 1
was set up by the shell before it ran; the program never knows the difference.

---

## Board summary

- **CPU:** many processes, one core, each thinks it runs continuously
- **Memory:** same virtual address `0x1b38`, private physical memory each
- **I/O:** same fd 0/1/2 in every process, meaning whatever the shell chose

All three are the operating system keeping one promise to every process:
*you have the machine to yourself.*
