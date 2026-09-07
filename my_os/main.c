#include "proc.h"
#include "types.h"
#define MMIO_OFFSET 0x100000000UL
#define UART0_BASE (0x10000000L + MMIO_OFFSET)
#define UART0_THR (UART0_BASE + 0)
#define UART0_LSR (UART0_BASE + 5)
void kinit();
void kvminit();
void kvminithart();
void trapinithart();
void procinit();
void userinit();
void scheduler();

/**
 * uart_putc
 * What it does: Sends a single character to the UART (serial port) chip so it appears on the screen.
 * Why it exists: This is the lowest-level printing function. It waits until the hardware says
 * "I am ready", and then writes the character to the transmission register.
 */
void uart_putc(char c) {
	volatile uint8* lsr = (uint8*)UART0_LSR;
	volatile uint8* thr = (uint8*)UART0_THR;
	while ((*lsr & (1 << 5)) == 0) { }
	*thr = c;
}

/**
 * print_string
 * What it does: Prints a full sentence or string to the screen by calling uart_putc in a loop.
 * Why it exists: Sending one character at a time is tedious. This makes it easy for the Kernel
 * to print readable messages (like "Hello, VM running!").
 */
void print_string(const char* s) {
	while (*s != '\0') {
		uart_putc(*s);
		s++;
	}
}

/**
 * start
 * What it does: This is the very first C function that runs when the OS boots up.
 * Why it exists: The assembly bootloader sets up a stack and then jumps here.
 * This function turns on memory management, initializes the process table, configures
 * interrupts, injects the first user program, and finally kicks off the scheduler loop!
 */
void start(uint64 hartid) {
	if (hartid == 0) {
		kinit();
		kvminit();
		kvminithart();
		procinit();
		trapinithart();
		print_string("Hello, VM running. Launching User Space...\n");
		userinit();
		scheduler();
	}
	while (1) { }
}
