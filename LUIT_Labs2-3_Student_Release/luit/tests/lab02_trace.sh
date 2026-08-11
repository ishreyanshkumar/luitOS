#!/bin/sh
OUT=$(mktemp)
(sleep 4; printf 'trace ls\n'; sleep 4) | timeout 20 qemu-system-riscv64 -machine virt -bios default -kernel kernel.elf -m 128M -smp 1 -nographic -drive file=fs.img,if=none,format=raw,id=x0 -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0 > "$OUT" 2>&1 || true
pass=1
grep -q "trace events" "$OUT" || { echo "FAIL: no trace output"; pass=0; }
grep -q "exec(" "$OUT" || { echo "FAIL: no fork inheritance"; pass=0; }
grep -q "open(" "$OUT" || { echo "FAIL: open not recorded"; pass=0; }
[ $pass -eq 1 ] && echo "[PASS] lab02 trace" || { cat "$OUT"; exit 1; }
rm -f "$OUT"
