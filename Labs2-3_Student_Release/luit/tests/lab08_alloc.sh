#!/bin/sh
# Lab 8 public test: allocator contention instrumentation reports per-hart lock
# acquisitions, and the conservation invariant holds before and after a
# multi-hart allocation storm.
OUT=$(mktemp)
(sleep 4; printf 'alloctest\n'; sleep 5) | timeout 18 qemu-system-riscv64 -machine virt -bios default -kernel kernel.elf -m 128M -smp 4 -nographic -drive file=fs.img,if=none,format=raw,id=x0 -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0 > "$OUT" 2>&1 || true
pass=1
grep -q "audit before: 0 OK" "$OUT" || { echo "FAIL: audit before"; pass=0; }
grep -q "audit after: 0 OK" "$OUT" || { echo "FAIL: conservation violated"; pass=0; }
grep -q "lock acquisitions total=" "$OUT" || { echo "FAIL: no contention stats"; pass=0; }
[ $pass -eq 1 ] && echo "[PASS] lab08 alloc: contention instrumentation + conservation audit" || { cat "$OUT"; exit 1; }
rm -f "$OUT"
