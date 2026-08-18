# Lab 12: silicon — FDT, HAL & Indigenous Silicon

*Weight: 3% of course grade · You will touch: hal/shakti/ or hal/vega/, kernel/fdt.c (team lab)*

**Goal.** Take Luit to real Indian RISC-V silicon. The SHAKTI and VEGA backends are honest stubs: they compile, they panic, and their READMEs say why — nobody invented register maps. Your team of three replaces panics with documented reality.

**Tasks.**
1. Extend the FDT parser for your board's tree (interrupt-parent chains, clock frequencies). The parser's property-order-independent design exists because of a real bug — docs/DEBUGGING.md tells that story; it is your reference.
2. Implement `hal_console_*` and `hal_intc_*` from the board's ACTUAL documentation, citing section numbers in comments. The SBI timer path should carry over from qemu_virt — verify that claim, don't assume it.
3. Boot to the `luit$` prompt on the SHAKTI/VEGA FPGA bitstream (or the vendor cycle-accurate simulator where boards are contended) and demo to a TA. Block device is a stretch goal (+2%).

**Deliverables.** The demo, a code review against the no-raw-MMIO-outside-HAL rule, and a bring-up journal: what the docs said, what the hardware did, and what you learned where they differed.

**Viva seeds.** What did the device tree on real silicon omit or get wrong, and how did you find out?

---

## Ground rules (all labs)

* Branch from `release/lab12`; `make grade LAB=12` must pass before submission; CI runs the same plus hidden tests.
* Your kernel must still pass **all baseline tests** — regressions cost marks even when the new feature works.
* The LLM policy for this lab is in `docs/LLM_POLICY.md`. Log every AMBER session as specified there.
