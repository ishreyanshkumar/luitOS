#!/bin/sh
# Lab 11 public test: (1) a logged transaction commits and installs; (2) a crash
# injected right after the commit point is REPLAYED by recovery on remount.
OUT1=$(mktemp); OUT2=$(mktemp)
# part 1: committed transaction installs
(sleep 4; printf 'ljtest\n'; sleep 3) | timeout 14 qemu-system-riscv64 -machine virt -bios default -kernel kernel.elf -m 128M -smp 1 -nographic -drive file=fs.img,if=none,format=raw,id=x0 -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0 > "$OUT1" 2>&1 || true
# part 2: crash + recovery on a scratch copy
cp fs.img fs.crashtest.img
(sleep 4; printf 'ljcrash\n'; sleep 2) | timeout 14 qemu-system-riscv64 -machine virt -bios default -kernel kernel.elf -m 128M -smp 1 -nographic -drive file=fs.crashtest.img,if=none,format=raw,id=x0 -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0 > /dev/null 2>&1 || true
(sleep 4; printf 'ljcrash v\n'; sleep 2) | timeout 14 qemu-system-riscv64 -machine virt -bios default -kernel kernel.elf -m 128M -smp 1 -nographic -drive file=fs.crashtest.img,if=none,format=raw,id=x0 -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0 > "$OUT2" 2>&1 || true
rm -f fs.crashtest.img
pass=1
grep -q "journal transaction: OK-COMMITTED" "$OUT1" || { echo "FAIL: transaction did not commit/install"; pass=0; }
grep -q "recovery after crash: OK-REPLAYED" "$OUT2" || { echo "FAIL: recovery did not replay committed txn"; pass=0; }
[ $pass -eq 1 ] && echo "[PASS] lab11 journal: commit+install and crash recovery replay" || { echo "--- p1 ---"; cat "$OUT1"; echo "--- p2 ---"; cat "$OUT2"; exit 1; }
rm -f "$OUT1" "$OUT2"
