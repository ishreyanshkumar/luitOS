#!/bin/sh
# Lab 9 public test (fsck component): the consistency checker validates a
# populated filesystem (files with direct+indirect blocks, nested dirs) as
# consistent, repeatably.
OUT=$(mktemp)
(sleep 4; printf 'fscktest\n'; sleep 3) | timeout 14 qemu-system-riscv64 -machine virt -bios default -kernel kernel.elf -m 128M -smp 1 -nographic -drive file=fs.img,if=none,format=raw,id=x0 -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0 > "$OUT" 2>&1 || true
pass=1
grep -q "fsck on populated fs: 0 CONSISTENT" "$OUT" || { echo "FAIL: fsck flagged a valid fs"; pass=0; }
grep -q "fsck repeatable: OK" "$OUT" || { echo "FAIL: fsck not repeatable"; pass=0; }
[ $pass -eq 1 ] && echo "[PASS] lab09 fsck: consistency check on populated fs" || { cat "$OUT"; exit 1; }
rm -f "$OUT"
