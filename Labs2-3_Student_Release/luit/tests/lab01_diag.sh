#!/bin/sh
# Lab 1 public test: pstree (ppid), syscalls (generated ABI), fdinfo (fdstat).
OUT=$(mktemp)
(sleep 4; printf 'pstree\n'; sleep 1; printf 'syscalls\n'; sleep 2) | timeout 16 qemu-system-riscv64 -machine virt -bios default -kernel kernel.elf -m 128M -smp 1 -nographic -drive file=fs.img,if=none,format=raw,id=x0 -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0 > "$OUT" 2>&1 || true
pass=1
grep -q "init(1)" "$OUT" || { echo "FAIL: pstree missing init"; pass=0; }
grep -q "sh(2)" "$OUT" || { echo "FAIL: pstree missing sh child (ppid broken)"; pass=0; }
grep -q "syscalls:" "$OUT" || { echo "FAIL: syscalls/abimeta"; pass=0; }
grep -q "fork" "$OUT" || { echo "FAIL: abimeta names"; pass=0; }
[ $pass -eq 1 ] && echo "[PASS] lab01 diagnostics: pstree + syscalls + fdstat" || { cat "$OUT"; exit 1; }
rm -f "$OUT"
