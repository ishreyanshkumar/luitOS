#!/bin/sh
OUT=$(mktemp)
(sleep 4; printf 'usitest\n'; sleep 5) | timeout 18 qemu-system-riscv64 -machine virt -bios default -kernel kernel.elf -m 128M -smp 1 -nographic -drive file=fs.img,if=none,format=raw,id=x0 -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0 > "$OUT" 2>&1 || true
pass=1
grep -q "u_getpid=.* OK" "$OUT" || { echo "FAIL: fast getpid"; pass=0; }
grep -q "torn=0 OK" "$OUT" || { echo "FAIL: torn snapshot"; pass=0; }
[ $pass -eq 1 ] && echo "[PASS] lab03 usysinfo" || { cat "$OUT"; exit 1; }
rm -f "$OUT"
