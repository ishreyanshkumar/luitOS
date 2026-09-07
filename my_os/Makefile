# Define the prefix for our RISC-V cross-compiler tools
TOOLPREFIX = riscv64-unknown-elf-

# Set up the variables for the Compiler (CC), Linker (LD), and Disassembler (OBJDUMP)
CC = $(TOOLPREFIX)gcc
LD = $(TOOLPREFIX)ld
OBJDUMP = $(TOOLPREFIX)objdump

# Basic warnings and debugging info
CFLAGS = -Wall -Werror -O -fno-omit-frame-pointer -ggdb -gdwarf-2

# The really important OS flags:
# -mcmodel=medany: Allows the kernel to run in the upper half of memory
# -ffreestanding & -nostdlib: Tells GCC "don't expect standard libraries or a main() function"
CFLAGS += -MD -mcmodel=medany -ffreestanding -fno-common -nostdlib -mno-relax
CFLAGS += -march=rv64gc -mabi=lp64d -fno-stack-protector -fno-pie -no-pie
CFLAGS += -I.

# Find all .c and .S files in our directory automatically
SRCS_C = $(wildcard *.c)
SRCS_S = $(wildcard *.S)

# Tell Make that for every .c or .S file, we expect a corresponding .o file
OBJS = $(SRCS_C:.c=.o) $(SRCS_S:.S=.o)

# The default target when you just run 'make'
all: kernel.elf

# Rule: How to turn a .c file into a .o file
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

# Rule: How to turn a .S file into a .o file
%.o: %.S
	$(CC) $(CFLAGS) -c -o $@ $<

# Rule: Build kernel.elf using our linker script
kernel.elf: $(OBJS) kernel.ld
	$(LD) -z max-page-size=4096 -T kernel.ld -o kernel.elf $(OBJS)
	$(OBJDUMP) -S kernel.elf > kernel.asm
	$(OBJDUMP) -t kernel.elf > kernel.sym

QEMU = qemu-system-riscv64
QEMUOPTS = -machine virt -bios default -kernel kernel.elf -m 128M -smp 1 -nographic

# This is the target you tried to run!
qemu: kernel.elf
	$(QEMU) $(QEMUOPTS)

clean:
	rm -f *.o *.d kernel.elf kernel.asm kernel.sym

.PHONY: all qemu clean

