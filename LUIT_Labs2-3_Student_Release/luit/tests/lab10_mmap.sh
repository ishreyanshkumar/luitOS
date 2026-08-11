#!/bin/sh
# Lab 10 public test: lazy file-backed mmap read (fault-in) and MAP_SHARED
# write-back on munmap.
OUT=$(mktemp)
(sleep 4; printf 'mmaptest\n'; sleep 4) | timeout 16 qemu-system-riscv64 -machine virt -bios default -kernel kernel.elf -m 128M -smp 1 -nographic -drive file=fs.img,if=none,format=raw,id=x0 -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0 > "$OUT" 2>&1 || true
pass=1
grep -q "lazy read: OK" "$OUT" || { echo "FAIL: lazy fault-in"; pass=0; }
grep -q "write-back: OK" "$OUT" || { echo "FAIL: MAP_SHARED write-back"; pass=0; }
[ $pass -eq 1 ] && echo "[PASS] lab10 mmap: lazy fault-in + write-back" || { cat "$OUT"; exit 1; }
rm -f "$OUT"
