#!/bin/sh
OUT=$(mktemp)
(sleep 4; printf 'cowtest\n'; sleep 5) | timeout 18 qemu-system-riscv64 -machine virt -bios default -kernel kernel.elf -m 128M -smp 1 -nographic -drive file=fs.img,if=none,format=raw,id=x0 -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0 > "$OUT" 2>&1 || true
pass=1
grep -q "OK-LAZY" "$OUT" || { echo "FAIL: not lazy"; pass=0; }
grep -q "isolation: parent buf\[0\]=1 OK" "$OUT" || { echo "FAIL: isolation"; pass=0; }
grep -q "copyout-COW: OK" "$OUT" || { echo "FAIL: copyout-COW"; pass=0; }
grep -q "pgaudit=0 OK" "$OUT" || { echo "FAIL: pgaudit"; pass=0; }
[ $pass -eq 1 ] && echo "[PASS] lab05 cow" || { cat "$OUT"; exit 1; }
rm -f "$OUT"
