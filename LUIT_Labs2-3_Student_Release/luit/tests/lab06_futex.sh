#!/bin/sh
# Lab 6 public test: clone shares the address space; the futex mutex serializes
# a shared counter with no lost updates across harts.
OUT=$(mktemp)
(sleep 4; printf 'futextest\n'; sleep 6) | timeout 20 qemu-system-riscv64 -machine virt -bios default -kernel kernel.elf -m 128M -smp 4 -nographic -drive file=fs.img,if=none,format=raw,id=x0 -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0 > "$OUT" 2>&1 || true
pass=1
grep -q "counter=6000 expected=6000 OK" "$OUT" || { echo "FAIL: futex mutex lost updates"; pass=0; }
grep -q "shared-address-space: OK" "$OUT" || { echo "FAIL: clone did not share AS"; pass=0; }
[ $pass -eq 1 ] && echo "[PASS] lab06 futex: clone + futex mutex" || { cat "$OUT"; exit 1; }
rm -f "$OUT"
