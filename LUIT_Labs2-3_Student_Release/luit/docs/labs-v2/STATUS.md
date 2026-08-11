# CS3106L Lab Redesign — Final Status & Manifest (QEMU-only)

*Dr. Satyajit Das · Department of Computer Science and Engineering · IIT Guwahati*

Per the QEMU-only completion decision, all labs are conducted and graded on QEMU.
Physical-silicon bring-up (Lab 12 bonus) is explicitly out of scope; the pinned
QEMU `sifive_u` target is the graded portability path and is verified.

## VERIFIED KERNEL CODE — 11 of 12 labs

Every lab below was compiled warning-clean (-Werror), booted on QEMU, and tested;
the baseline 9/9 grade is preserved with no regression in every case. Each ships
a public test (`make grade LAB=N`) and a staff reference in `staff/reference/`.

| Lab | Title | Files | Verified behaviour |
|-----|-------|-------|--------------------|
| 1 | Diagnostics | pstree/fdinfo/syscalls + ppid/fdstat/abimeta | correct process tree; 31-syscall ABI dump; fd metadata |
| 2 | Kernel tracing | `kernel/trace.{c,h}`, `user/trace.c` | 129 events; fork inheritance; overflow count 908 |
| 3 | Seqlock info page | `kernel/usysinfo.{c,h}` | 20000 snapshots torn=0; RO write faults; no leak |
| 4 | Event delivery | `kernel/event.c` | timer alarm on alt stack; full register restore |
| 5 | Copy-on-write | COW in `kernel/vm.c`, `kernel/pgaudit.c` | fork 64pg copies 7 lazy; copyout-COW; pgaudit=0; 1&4 harts |
| 6 | Threads + futexes | `kernel/futex.{c,h}`, clone in `proc.c` | counter=6000 across 4 harts; clone shares AS |
| 8 | Scalable allocator | `kernel/palloc.c` instrumentation | per-hart lock-acquisition counts; conservation audit=0 |
| 9 | LuitFS evolution | `sys_rename` + `kernel/fsck.c` | atomic rename; fsck validates populated fs |
| 10 | Integrated mmap | `kernel/mmap.c` | lazy file-backed fault-in; MAP_SHARED write-back |
| 11 | Journalling (FLAGSHIP) | `kernel/log.c` + mkfs log region | WAL commit+install; committed txn REPLAYED after injected crash |
| 12 | Portability (FLAGSHIP) | `hal/sifive_u/*` + FDT + boot-hart election | same core boots on sifive_u; UART/mem discovered via FDT |

Two real kernel bugs were found and fixed during verification, now documented in
the specs as student warnings: a one-page-per-process leak (uvmfree skips VAs
above sz; the info page is freed explicitly in freeproc) and a missing
sfence_vma() in the COW fault handler (a stale RO TLB entry corrupted memory far
from the fault). A third — the sifive_u boot hart being hart 1 not hart 0 — was
fixed with runtime CAS-based boot-hart election.

## NOT BUILT — 1 lab

- **Lab 7 (VirtIO-net).** The only lab with no kernel code. QEMU accepts a
  `virtio-net-device` on a virtio-mmio slot and the kernel boots with it present
  (discovery point confirmed), but the two-queue DMA driver + packet path is not
  implemented. The full spec exists (`docs/labs-v2/lab07.md`). This is the single
  remaining implementation gap.

## COMPLETE — design, infrastructure, docs

- Stages 1-3: audit, sequence (32 contact hours), and all 12 full student specs.
- `make grade LAB=N` unified harness (`tests/run_lab.sh`): baseline regression +
  the lab's public test with individual results.
- Public tests for 11 labs (`tests/labNN_*.sh`); staff references in `staff/reference/`.
- Branch structure: `release/lab01..12`, `staff/solution-lab01..12`, `release/base-v1.0`.
- Release-engineering guide (`docs/RELEASE.md`): clean student release via orphan commit.
- Stage 7 integration & gap report (`docs/labs-v2/INTEGRATION.md`): dependency
  graph, migration table, risks, per-lab release gates.

## REMAINING REFINEMENTS (not blockers)

- Lab 7 driver (the one implementation gap above).
- Lab 9: block checksums + on-disk v2 + migration (rename + fsck done).
- Lab 11: ≥200-trial random crash campaign (deterministic commit+recovery proven).
- Lab 12: RAM-fs fallback for a full shell on sifive_u (UART/FDT/boot-hart proven).
- Stage 4 formal staff spec documents; hidden-test suites (public tests exist).

## HOW TO BUILD & GRADE

    cd luit
    make                    # build kernel.elf + fs.img (qemu_virt)
    make grade              # baseline 9/9
    make grade LAB=N        # baseline regression + lab N public test (N=1..12)
    make HAL=sifive_u       # build the portability target (Lab 12)

Toolchain if missing: `apt-get install -y gcc-riscv64-unknown-elf qemu-system-misc`.
