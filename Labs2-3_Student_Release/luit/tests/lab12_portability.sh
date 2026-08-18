#!/bin/sh
# Lab 12 public test: the SAME kernel core builds with the sifive_u HAL and boots
# on the sifive_u board, discovering its UART/PLIC/memory from the device tree
# (different addresses than qemu virt) - proving portability with no core change.
OUT=$(mktemp)
# build for sifive_u
make clean >/dev/null 2>&1
make HAL=sifive_u >/dev/null 2>&1 || { echo "FAIL: sifive_u build"; exit 1; }
# boot on the sifive_u machine (needs >=2 harts; hart 1 is the boot hart)
timeout 18 qemu-system-riscv64 -machine sifive_u -bios default -kernel kernel.elf -m 256M -smp 2 -nographic > "$OUT" 2>&1 || true
pass=1
grep -q "BrahmaputraOS" "$OUT" || { echo "FAIL: kernel banner not reached on sifive_u"; pass=0; }
grep -q "uart  : 0x0000000010010000" "$OUT" || { echo "FAIL: SiFive UART not discovered via FDT"; pass=0; }
grep -q "palloc:" "$OUT" || { echo "FAIL: memory init not reached"; pass=0; }
# restore qemu_virt build
make clean >/dev/null 2>&1; make >/dev/null 2>&1
[ $pass -eq 1 ] && echo "[PASS] lab12 portability: same core boots on sifive_u, UART/mem discovered via FDT" || { cat "$OUT"; exit 1; }
rm -f "$OUT"
