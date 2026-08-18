#!/bin/sh
# Lab 9 public test (rename component): atomic rename moves a name; old vanishes,
# new carries the data, rename onto an existing name is refused.
OUT=$(mktemp)
(sleep 4; printf 'renametest\n'; sleep 3) | timeout 16 qemu-system-riscv64 -machine virt -bios default -kernel kernel.elf -m 128M -smp 1 -nographic -drive file=fs.img,if=none,format=raw,id=x0 -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0 > "$OUT" 2>&1 || true
pass=1
grep -q "old name gone: OK" "$OUT" || { echo "FAIL: old name still exists"; pass=0; }
grep -q "new name data: 'hello-rename' OK" "$OUT" || { echo "FAIL: data not moved"; pass=0; }
grep -q "rename onto existing: OK-REFUSED" "$OUT" || { echo "FAIL: overwrite not refused"; pass=0; }
[ $pass -eq 1 ] && echo "[PASS] lab09 rename: atomic move + overwrite refusal" || { cat "$OUT"; exit 1; }
rm -f "$OUT"
