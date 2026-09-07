# Luit page-fault GDB helpers.
# Use after the normal .gdbinit has connected to QEMU:
#     source docs/pagefault.gdb

set pagination off

# Stop at usertrap only for instruction/load/store page faults.
define pfbreak
  break usertrap if ($scause == 12 || $scause == 13 || $scause == 15)
end
document pfbreak
Create a conditional breakpoint at usertrap for scause 12, 13, or 15 only.
This avoids stopping on every system call.
end

# Decode the low ten bits of an Sv39 PTE.
define pteflags
  set $e = (unsigned long)$arg0
  printf "pte=0x%lx  ppn-base-pa=0x%lx  flags=0x%lx [", $e, (($e >> 10) << 12), ($e & 0x3ff)
  if ($e & 0x1)
    printf "V"
  end
  if ($e & 0x2)
    printf " R"
  end
  if ($e & 0x4)
    printf " W"
  end
  if ($e & 0x8)
    printf " X"
  end
  if ($e & 0x10)
    printf " U"
  end
  if ($e & 0x20)
    printf " G"
  end
  if ($e & 0x40)
    printf " A"
  end
  if ($e & 0x80)
    printf " D"
  end
  if ($e & 0x100)
    printf " COW"
  end
  printf "]\n"
end
document pteflags
pteflags <pte-value> -- decode the Luit/RISC-V Sv39 PTE flags.
The printed PA is the PPN-derived base. Luit normally uses 4 KiB user leaves.
end

# Manually walk Luit's Sv39 page table without calling the kernel walk().
# Luit identity-maps managed RAM in the kernel region, so physical addresses
# of page-table pages can be inspected as kernel virtual addresses.
define ptewalk
  set $root = (unsigned long *)$arg0
  set $v = (unsigned long)$arg1
  set $pf_leaf = 0
  set $pf_pte = 0
  printf "Sv39 walk: root=%p va=0x%lx\n", $root, $v

  set $i2 = (($v >> 30) & 0x1ff)
  set $e2 = $root[$i2]
  printf " L2 index=%lu entry=0x%lx\n", $i2, $e2
  if (($e2 & 1) == 0)
    printf " -> INVALID at L2\n"
  else
    if ($e2 & 0xe)
      set $pf_leaf = &$root[$i2]
      set $pf_pte = $e2
      printf " -> LEAF at L2, ptr=%p\n", $pf_leaf
      pteflags $e2
    else
      set $l1pa = (($e2 >> 10) << 12)
      set $l1 = (unsigned long *)$l1pa
      set $i1 = (($v >> 21) & 0x1ff)
      set $e1 = $l1[$i1]
      printf " L1 index=%lu table=%p entry=0x%lx\n", $i1, $l1, $e1
      if (($e1 & 1) == 0)
        printf " -> INVALID at L1\n"
      else
        if ($e1 & 0xe)
          set $pf_leaf = &$l1[$i1]
          set $pf_pte = $e1
          printf " -> LEAF at L1, ptr=%p\n", $pf_leaf
          pteflags $e1
        else
          set $l0pa = (($e1 >> 10) << 12)
          set $l0 = (unsigned long *)$l0pa
          set $i0 = (($v >> 12) & 0x1ff)
          set $e0 = $l0[$i0]
          printf " L0 index=%lu table=%p entry=0x%lx\n", $i0, $l0, $e0
          if (($e0 & 1) == 0)
            printf " -> INVALID at L0\n"
          else
            set $pf_leaf = &$l0[$i0]
            set $pf_pte = $e0
            printf " -> LEAF at L0, ptr=%p\n", $pf_leaf
            pteflags $e0
          end
        end
      end
    end
  end
end
document ptewalk
ptewalk <pagetable-root> <va> -- manually walk an Sv39 page table.
For a valid leaf it leaves $pf_leaf pointing to the PTE and $pf_pte holding
its value. Example while stopped in usertrap:
  set $p = cpus[$tp].proc
  ptewalk $p->pagetable $stval
end

# Print current process VM state at a user trap.
define pfstate
  set $p = cpus[$tp].proc
  if ($p == 0)
    printf "no current process in cpus[$tp].proc; use this while stopped in a process kernel path\n"
  else
    printf "pid=%d name=%s p=%p hart=%ld\n", $p->pid, $p->name, $p, $tp
    printf "p->sz=0x%lx pagetable=%p\n", $p->sz, $p->pagetable
    printf "scause=0x%lx sepc=0x%lx stval=0x%lx satp=0x%lx\n", $scause, $sepc, $stval, $satp
    printf "fault-page=0x%lx offset=0x%lx\n", ($stval & ~0xfff), ($stval & 0xfff)
  end
end
document pfstate
Print the current process and page-fault CSRs. Use while stopped in usertrap().
end

# Compare active satp root PPN with the current process page-table root.
define satpcheck
  set $p = cpus[$tp].proc
  if ($p == 0)
    printf "no current process in cpus[$tp].proc\n"
  else
    set $satp_ppn = ($satp & 0x00000fffffffffff)
    set $pt_ppn = (((unsigned long)$p->pagetable) >> 12)
    printf "satp mode=%lu satp.ppn=0x%lx process-pt.ppn=0x%lx\n", ($satp >> 60), $satp_ppn, $pt_ppn
    if ($satp_ppn == $pt_ppn)
      printf " -> active satp root is the current process page table\n"
    else
      printf " -> active satp root differs from the current process page table\n"
    end
  end
end
document satpcheck
Compare the active satp root with the current process page-table root.
In Luit usertrap(), they should match because uservec does not switch satp.
end

echo [pagefault.gdb] helpers loaded: pfbreak, pfstate, ptewalk, pteflags, satpcheck\n
