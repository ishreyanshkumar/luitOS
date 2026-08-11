#!/bin/sh
# Lab 4 public test: the timer alarm fires (delivered on the alt stack) and
# sigreturn restores full register state so the interrupted loop is unaffected.
OUT=$(mktemp)
(sleep 4; printf 'evtest\n'; sleep 8) | timeout 20 qemu-system-riscv64 -machine virt -bios default -kernel kernel.elf -m 128M -smp 1 -nographic -drive file=fs.img,if=none,format=raw,id=x0 -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0 > "$OUT" 2>&1 || true
pass=1
grep -q "alarm fired [1-9].* OK" "$OUT" || { echo "FAIL: alarm never fired"; pass=0; }
grep -q "registers survived handler) OK" "$OUT" || { echo "FAIL: register state clobbered"; pass=0; }
[ $pass -eq 1 ] && echo "[PASS] lab04 event: alarm delivery + full register restore" || { cat "$OUT"; exit 1; }
rm -f "$OUT"
