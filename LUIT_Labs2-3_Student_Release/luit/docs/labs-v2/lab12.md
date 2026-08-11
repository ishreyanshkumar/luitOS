# Lab 12 — FDT/HAL Portability & Indigenous Silicon (Flagship)

*CS3106L · Dr. Satyajit Das · IIT Guwahati · flagship · team lab · ~8 h take-home*

> **Boot the same kernel on a second machine.** This flagship makes LUIT's
> central claim real: the *same* kernel, unchanged, boots on QEMU `virt` and on
> one **pinned second target**, because all hardware knowledge lives in the FDT
> parser and the HAL. We pin an exact target and provide a RAM-backed fallback so
> the lab is completable in QEMU without physical silicon.

## 1. Educational objective
Prove a well-abstracted kernel is portable: bring LUIT up on a second target by
writing only a HAL backend and extending the FDT parser, changing **no** core
kernel code — and demonstrate that invariant.

## 2. Concepts covered
The boot flow; the flattened device tree; the HAL boundary; discovery vs
hardcoding; bring-up methodology (UART → interrupts → storage); claimed vs
verified portability.

## 3. Baseline components to read
`kernel/start.c`, `kernel/main.c` (boot flow, init order); `kernel/fdt.c` (the
parser to extend); `hal/qemu_virt/*` (the complete reference); `hal/shakti/*`,
`hal/vega/*` (honest stubs to make real); Book Ch 10.

## 4. Pinned target (this offering)
**Primary: QEMU `-machine sifive_u`** — a different RISC-V board than `virt`, with
a different UART, PLIC layout, and memory map. Chosen because it is concretely
available to every student in QEMU, has a real distinct device tree, and forces
genuine HAL/FDT work. A physical SHAKTI/VEGA board, where available, is an
**optional bonus** demonstrated to staff.
**Fallback storage:** a RAM-backed block device, so the target boots to a shell
without a working disk controller.

## 5. Main implementation tasks
**A** extend the FDT parser: parse the target's UART base+IRQ, PLIC, memory
range, hart count — all discovered, none hardcoded, without regressing `virt`.
**B** the HAL backend: hal_console_* (its UART), hal_intc_* (its interrupt
controller), hal_timer_* (verify SBI carries over), a RAM-backed hal_block_*;
replace the honest-stub panics with real, documented register access.
**C** bring-up order + milestones: (1) UART output — banner appears; (2) UART
input + interrupts — shell echoes; (3) storage (RAM-fs) — ls works, a file
round-trips. Each is a checkpoint.
**D** prove the core is unchanged: a **diff** showing only hal/<target>/* and
additive fdt.c parsing changed; boot the same kernel sources on both `virt` and
the target (different HAL selected at build), each reaching `luit$`.
**E** bring-up journal: what the tree/docs said, what the hardware did, every
mismatch. Graded — real bring-up is a story of mismatches.

## 6. Requirements that differ from xv6
No xv6 lab targets a second machine or a HAL; xv6 is virt-only. The portability
proof, the discovery discipline, and the bring-up journal are entirely LUIT.

## 7. Required interfaces
The full HAL for the pinned target; FDT parsing for its tree; build selection
`make HAL=sifive_u`.

## 8. Required data structures
The target's fdt_info population; the HAL backend's device state.

## 9. Concurrency and locking requirements
Multi-hart bring-up on the target (if multi-hart): secondaries online via its
mechanism; the shared kernel page table and per-hart trap setup work unchanged
(the point).

## 10. Error-handling requirements
Missing/invalid device in the target tree → clear message, not a silent hang
(the "report before you rely" discipline); RAM-fs fallback if no block device.

## 11. Integration with previous labs
Exercises the HAL/FDT abstraction **Lab 7** used; everything the kernel does —
VM, traps, scheduling, FS — must work unchanged on the new target, so this lab
transitively depends on all of them.

## 12. Public tests (`make grade LAB=12`)
`make HAL=sifive_u` builds; the same kernel sources compile for both targets; the
target boots to the banner; the shell echoes input; ls and a file round-trip on
the RAM-fs fallback.

## 13. Hidden tests
No-core-change: a diff shows kernel/ core logic unchanged (only HAL + additive
FDT); discovery not hardcode (perturb the tree's UART address, kernel still finds
it); virt not regressed; multi-hart (if applicable) secondaries online.

## 14. Performance / correctness measurement
Boot-to-shell time on the target; per-milestone timing; (bonus) physical-board
metrics if demonstrated.

## 15. Required report (≤3 pages, team)
The target's tree and how you parsed it; the HAL backend per device; the bring-up
journal (doc-vs-reality mismatches); the diff proving the core is unchanged;
(bonus) physical-board results.

## 16. Viva questions (per team member)
What in the target's tree differs from virt, and how did you find it? Show that
no core code changed — why is that the whole point? Which device first and why?
Where did the documentation lie, and how did you discover it?

## 17. Expected workload
~8h (team of 3): 2h FDT parsing, 3h HAL backend, 2h bring-up/milestones, 1h
journal+diff.

## 18. Starter code provided
`hal/sifive_u/` skeleton (honest stubs); FDT parsing hooks; a RAM-block-device
skeleton; `make HAL=` selection; `tests/lab12/` boot-milestone harness.

## 19. Staff-only reference requirements
A working sifive_u HAL + FDT extension booting to a shell; the no-core-change
diff; boot-milestone baselines; (bonus) physical-board notes.

## 20. Common incorrect approaches
Hardcoding the target's UART address (discovery test fails); editing core code to
special-case the target (diff test fails); regressing virt; a silent hang on a
missing device.

## 21. Suggested rubric (100, team + individual viva)
FDT parsing 18 · HAL backend 25 · bring-up milestones 20 · no-core-change proof
15 · journal 10 · individual viva 12. Bonus (physical board) +up to 10.

## 22. LLM-use declaration
Appendix (per team). The target's registers are in its docs, not an LLM's
training set — you'll see. Declare any use for the FDT/HAL boilerplate.

## 23. Anti-copying check
No public xv6 second-target lab. The pinned target's HAL and the no-core-change
diff are LUIT-specific. The "where did the docs lie" journal and viva require
having done the bring-up; a physical board (bonus) is uncopyable by construction.
