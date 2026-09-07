# BrahmaputraOS / Luit -- .gdbinit
# Usage: `make qemu-gdb` in one terminal, `gdb-multiarch kernel.elf` in another.
# If gdb refuses to load this file, add to ~/.config/gdb/gdbinit:
#     add-auto-load-safe-path <path-to-your-luit-checkout>/.gdbinit

set confirm off
set architecture riscv:rv64
target remote localhost:1234
symbol-file kernel.elf
set disassemble-next-line auto
set riscv use-compressed-breakpoints yes

# ---- Luit helper commands ------------------------------------------------

define trapregs
  printf "scause = 0x%lx\n", $scause
  printf "sepc   = 0x%lx\n", $sepc
  printf "stval  = 0x%lx\n", $stval
  printf "sstatus= 0x%lx\n", $sstatus
  printf "satp   = 0x%lx\n", $satp
end
document trapregs
Dump the supervisor trap CSRs (scause/sepc/stval/sstatus/satp).
Run this the moment you hit a breakpoint in usertrap or kerneltrap.
end

define procs
  set $i = 0
  while $i < 16
    if proc[$i].state != 0
      printf "pid %d  state %d  name %s\n", proc[$i].pid, proc[$i].state, proc[$i].name
    end
    set $i = $i + 1
  end
end
document procs
Walk the process table and print every slot that is not UNUSED.
State numbers: see enum procstate in kernel/defs.h.
end

define tf
  if $arg0 != 0
    printf "trapframe at %p\n", $arg0
    printf "  epc = 0x%lx  sp = 0x%lx  ra = 0x%lx\n", ((struct trapframe*)$arg0)->epc, ((struct trapframe*)$arg0)->sp, ((struct trapframe*)$arg0)->ra
    printf "  a0..a5 = 0x%lx 0x%lx 0x%lx 0x%lx 0x%lx 0x%lx\n", ((struct trapframe*)$arg0)->a0, ((struct trapframe*)$arg0)->a1, ((struct trapframe*)$arg0)->a2, ((struct trapframe*)$arg0)->a3, ((struct trapframe*)$arg0)->a4, ((struct trapframe*)$arg0)->a5
  end
end
document tf
tf <trapframe pointer> -- print the saved user registers.
Typical use: tf myproc()->trapframe   (only valid in process context).
end

echo \n[Luit] connected. Helpers: trapregs, procs, tf <ptr>.\n
echo [Luit] Suggested first breakpoints: b usertrap / b syscall / b scheduler\n\n
