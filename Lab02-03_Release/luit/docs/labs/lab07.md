# Lab 7: net — Network Driver

*Weight: 5% of course grade · You will touch: hal/qemu_virt/virtio_net.c (new)*

**Goal.** Write a device driver: virtio-net, discovered through the device tree like everything else in Luit.

**Tasks.**
1. Probe the FDT virtio slots for DeviceID 1; negotiate features; set up TWO rings (RX and TX) where virtio-blk had one. Our fully-commented `virtio_blk.c` is your worked example of the ring protocol, descriptor chains, and every memory barrier — read it before writing a line.
2. Transmit and receive Ethernet frames; RX pre-posts buffers, TX posts on demand.
3. A small ARP-reply + UDP-echo user program rides on top (skeleton provided; the driver is the deliverable, not a network stack). QEMU's user-mode netdev is pre-wired; a host-side pytest checks the packets.

**Viva seeds.** Why does RX pre-post while TX doesn't? Pick one `__sync_synchronize()` in your driver and say what fails without it.

---

## Ground rules (all labs)

* Branch from `release/lab07`; `make grade LAB=7` must pass before submission; CI runs the same plus hidden tests.
* Your kernel must still pass **all baseline tests** — regressions cost marks even when the new feature works.
* The LLM policy for this lab is in `docs/LLM_POLICY.md`. Log every AMBER session as specified there.
