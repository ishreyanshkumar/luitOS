# BrahmaputraOS / Luit -- Teaching Base v1.0
TOOLPREFIX = riscv64-unknown-elf-
CC      = $(TOOLPREFIX)gcc
LD      = $(TOOLPREFIX)ld
OBJCOPY = $(TOOLPREFIX)objcopy
OBJDUMP = $(TOOLPREFIX)objdump
HOSTCC  = gcc

CFLAGS  = -Wall -Werror -O -fno-omit-frame-pointer -ggdb -gdwarf-2
CFLAGS += -MD -mcmodel=medany -ffreestanding -fno-common -nostdlib -mno-relax
CFLAGS += -march=rv64gc -mabi=lp64d -fno-stack-protector -fno-pie -no-pie
CFLAGS += -Ikernel -Ihal

# The teaching user binaries are intentionally RWX and run in QEMU without W^X
# enforcement, so binutils >= 2.39 prints a benign "LOAD segment with RWX
# permissions" warning for each one. Suppress it, but ONLY when the linker
# actually understands the flag, so older toolchains are left untouched.
LDFLAGS ?=
ifneq (,$(findstring no-warn-rwx-segments,$(shell $(LD) --help 2>/dev/null)))
LDFLAGS += --no-warn-rwx-segments
endif

KOBJS = kernel/entry.o kernel/start.o kernel/main.o kernel/printf.o \
        kernel/string.o kernel/sbi.o kernel/fdt.o kernel/palloc.o \
        kernel/spinlock.o kernel/sleeplock.o kernel/proc.o kernel/swtch.o \
        kernel/trap.o kernel/kernelvec.o kernel/uservec.o kernel/vm.o \
        kernel/syscall.o kernel/sysfile.o kernel/console.o kernel/exec.o \
        kernel/bio.o kernel/fs.o kernel/file.o kernel/pipe.o \
        kernel/initcode_blob.o \
        $(HAL_OBJS)

# Hardware-abstraction backend. The Lab 1 release targets QEMU virt.
# Other backends are retained as architecture examples and are not edited here.
HAL ?= qemu_virt
HAL_SRCS = $(wildcard hal/$(HAL)/*.c)
HAL_OBJS = $(HAL_SRCS:.c=.o)

UPROGS = user/init user/sh user/echo user/cat user/ls user/mkdir user/rm \
         user/wc user/grep user/kill user/ln user/ps user/meminfo user/vdemo \
         user/sleep user/pingpong user/pstree user/usertests user/forktest

ULIB = user/crt0.o user/ulib.o user/umalloc.o user/usys.o

all: kernel.elf fs.img

# ---- generated syscall interface (single source of truth: syscall.tbl) ----
kernel/syscallnums.h kernel/syscalltab.h user/usys.S &: kernel/syscall.tbl tools/gensyscalls.py
	python3 tools/gensyscalls.py

# ---- user programs (real, separately-linked ELF binaries) ----
user/%.o: user/%.c user/ulib.h
	$(CC) $(CFLAGS) -c -o $@ $<
user/%.o: user/%.S
	$(CC) $(CFLAGS) -c -o $@ $<

user/%: user/%.o $(ULIB) user/user.ld
	$(LD) $(LDFLAGS) -T user/user.ld -o $@ $< $(ULIB)

# initcode is raw (not ELF): loaded byte-for-byte by userinit(); its only
# job is exec("/init"), which pulls everything else from LuitFS.
user/initcode: user/initcode.S kernel/syscallnums.h
	$(CC) $(CFLAGS) -c -o user/initcode.o user/initcode.S
	$(LD) $(LDFLAGS) -N -e start -Ttext 0 -o user/initcode.out user/initcode.o
	$(OBJCOPY) -S -O binary user/initcode.out user/initcode

kernel/initcode_blob.S: user/initcode tools/geninitcode.sh
	sh tools/geninitcode.sh > kernel/initcode_blob.S
kernel/initcode_blob.o: kernel/initcode_blob.S user/initcode
	$(CC) $(CFLAGS) -c -o $@ kernel/initcode_blob.S

# ---- LuitFS image ----
mkfs/mkfs: mkfs/mkfs.c kernel/fs.h
	$(HOSTCC) -Wall -Werror -I. -o $@ mkfs/mkfs.c

fs.img: mkfs/mkfs $(UPROGS)
	mkfs/mkfs fs.img $(UPROGS)

hal/%.o: hal/%.c kernel/syscallnums.h
	$(CC) $(CFLAGS) -c -o $@ $<

kernel/%.o: kernel/%.c kernel/syscallnums.h
	$(CC) $(CFLAGS) -c -o $@ $<
kernel/%.o: kernel/%.S
	$(CC) $(CFLAGS) -c -o $@ $<

kernel.elf: $(KOBJS) kernel/kernel.ld
	$(LD) $(LDFLAGS) -z max-page-size=4096 -T kernel/kernel.ld -o kernel.elf $(KOBJS)
	$(OBJDUMP) -S kernel.elf > kernel.asm
	$(OBJDUMP) -t kernel.elf > kernel.sym

# ---- running ----
NCPU ?= 4
CPUS ?= $(NCPU)
MEM  ?= 128M
QEMUOPTS  = -machine virt -bios default -kernel kernel.elf -m $(MEM) -smp $(CPUS) -nographic
QEMUOPTS += -drive file=fs.img,if=none,format=raw,id=x0
QEMUOPTS += -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0

qemu: kernel.elf fs.img
	qemu-system-riscv64 $(QEMUOPTS)

qemu-gdb: kernel.elf fs.img
	qemu-system-riscv64 $(QEMUOPTS) -S -gdb tcp::1234

grade: kernel.elf fs.img
	python3 tests/grade.py

lab01-check:
	python3 tests/lab01_check.py

# Remove host-OS metadata that may appear after downloading/extracting on
# Windows or macOS. These files are not part of the Luit source tree.
lab01-clean-metadata:
	find . -type f \
	  \( -name '*:Zone.Identifier' -o -name '.DS_Store' \
	     -o -name 'Thumbs.db' -o -name 'desktop.ini' \) -delete

clean:
	rm -f kernel/*.o kernel/*.d kernel/initcode_blob.S \
	      kernel/syscallnums.h kernel/syscalltab.h user/usys.S \
	      user/*.o user/*.d hal/*/*.o hal/*/*.d \
	      user/initcode user/initcode.out $(UPROGS) \
	      mkfs/mkfs fs.img kernel.elf kernel.asm kernel.sym

.PHONY: all qemu qemu-gdb grade lab01-check lab01-clean-metadata clean
