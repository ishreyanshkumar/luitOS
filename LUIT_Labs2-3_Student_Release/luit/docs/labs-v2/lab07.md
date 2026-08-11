# Lab 7 — VirtIO-net & Measured Packet Path

*CS3106L · Dr. Satyajit Das · IIT Guwahati · TWO-WEEK · ~10 h take-home*

> **Not the E1000.** The xv6 net lab drives an Intel E1000 on PCI; its solutions
> don't transfer to LUIT's VirtIO-mmio world. You have a fully-commented VirtIO-
> *block* driver as a model; generalize it to **VirtIO-net** with two queues,
> correct descriptor ownership, exhaustion handling, and a measured packet path.

## 1. Educational objective
Write a real DMA driver against discovered hardware, manage two descriptor rings
with correct ownership and interrupts, and measure the packet path.

## 2. Concepts covered
VirtIO queues (RX pre-post vs TX on-demand); DMA-safe buffers; descriptor
ownership; interrupts; bounded queues/exhaustion; FDT/HAL discovery; measurement.

## 3. Baseline components to read
`hal/qemu_virt/virtio_blk.c` — **the worked example** (ring setup, descriptor
chains, barriers, interrupts); `kernel/fdt.c` (discovery); the PLIC path.

## 4. Warm-up task
Discover VirtIO-net (device id 1) via FDT, negotiate features, bring up the two
virtqueues (RX=0, TX=1) without sending; print features and queue sizes.

## 5. Main implementation tasks
**A** RX: pre-post device-writable buffers; on RX interrupt harvest and re-post.
**B** TX: build header+payload chain, kick, reclaim on TX completion interrupt.
**C** bounded queue + exhaustion: drop with accounting, never deadlock/overrun.
**D** ARP + minimal UDP against a provided host echo (driver is the deliverable).
**E** stats + measurement: tx/rx/bytes, drops per cause, interrupts, occupancy;
throughput and loss under a flood; interrupt rate; occupancy toward exhaustion.

## 6. Requirements that differ from xv6
VirtIO not E1000; two-queue RX-pre-post/TX-on-demand asymmetry; exhaustion
accounting; the loss-vs-load measurement — the E1000 code/solution don't apply.

## 7. Required interfaces and system calls
HAL `hal_net_init/tx/rx/irq`; syscalls `net_send`, `net_recv`, `net_stats(struct netstat*)`.

## 8. Required data structures
Two virtq rings (RX,TX), DMA-aligned; bounded packet queue; `struct netstat
{tx,rx,drops_ring,drops_queue,irqs,occ_max;}`.

## 9. Concurrency and locking requirements
One lock per queue; interrupt handler acks first, then harvests; barriers around
descriptor publication and avail-idx (as in the block driver), each commented;
multi-hart TX serializes on the TX lock.

## 10. Error-handling requirements
Descriptor exhaustion: drop+count, no deadlock/overrun; malformed frames
dropped+counted; RX starvation recovers by re-posting; feature negotiation
refuses unsupported features.

## 11. Integration with previous labs
Exercises the HAL/FDT abstraction that Lab 12 also uses; uses Lab 2 tracing for
packet-path events; stats via a netstat syscall (Lab 3-style optional).

## 12. Public tests (`make grade LAB=7`)
Device discovered, queues initialized, features printed; ARP answered; UDP echo
round-trips 100 datagrams zero-loss at low rate; netstat nonzero tx/rx, zero drops.

## 13. Hidden tests
Exhaustion under flood: drops counted, no overrun, recovers; RX re-post sustains
receive; a barrier-removed build fails an integrity assertion; multi-hart TX no
corruption; malformed frame dropped not crashed.

## 14. Performance measurement
Throughput (Mbps) and loss vs offered load; interrupt rate; max occupancy near
exhaustion; a loss-vs-load table/graph.

## 15. Required report (≤3 pages)
RX-vs-TX asymmetry; exhaustion/backpressure design; barrier placement; the loss-
vs-load knee; interrupt-rate analysis.

## 16. Viva questions
Why pre-post RX but post TX on demand? Which descriptors are device-writable vs
-readable, and why does it matter? Point to a barrier and say what fails without
it. Behaviour the instant descriptors run out?

## 17. Expected workload
~10h/two weeks: 3h rings, 2h interrupts/exhaustion, 2h ARP/UDP, 2h measurement,
1h report.

## 18. Starter code provided
`hal/qemu_virt/virtio_net.c` skeleton (probe done); host echo + flood tools;
`user/nettest.c`; `tests/lab07/`; a provided minimal IP/UDP stack.

## 19. Staff-only reference requirements
Full two-queue driver; exhaustion accounting; barrier-correct publication; loss-
vs-load baselines; a barrier-removed variant for the integrity demo.

## 20. Common incorrect approaches
One queue for both directions; not re-posting RX (starvation); blocking on
exhaustion (deadlock); missing barriers (intermittent corruption under load).

## 21. Suggested rubric (100)
Discovery+init 12 · RX 18 · TX 15 · exhaustion 15 · ARP/UDP 10 · measurement 18 ·
viva 12.

## 22. LLM-use declaration
Appendix. VirtIO spec questions via LLM are fine; a generated driver you can't
defend on barriers/ownership fails viva.

## 23. Anti-copying check
Public net = E1000: different device, code, single queue. VirtIO two-queue
ownership, exhaustion accounting, and loss-vs-load are the walls; the RX/TX-
asymmetry and barrier viva reveal real work.
