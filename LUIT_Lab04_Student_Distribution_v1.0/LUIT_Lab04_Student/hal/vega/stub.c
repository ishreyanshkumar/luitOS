/* VEGA HAL BACKEND - Lab 12 territory.
 *
 * This backend COMPILES (CI builds HAL=vega on every push) but every entry
 * point panics: it is a contract to fill in, not working hardware support.
 * We do not invent register maps. When your team brings up a real VEGA
 * board (or its verified FPGA bitstream), implement each function against the
 * board's documentation and delete the panic - one device at a time, UART
 * first. The SBI-based timer path from qemu_virt should carry over unchanged;
 * start by copying hal/qemu_virt/timer.c and testing exactly that claim.
 */
#include "types.h"
#include "hal.h"
#include "riscv.h"
#include "defs.h"

static void todo(const char *fn)
{
    sbi_putchar('\n');
    for (const char *s = "vega hal: not implemented: "; *s; s++) sbi_putchar(*s);
    for (const char *s = fn; *s; s++) sbi_putchar(*s);
    sbi_putchar('\n');
    for (;;)
        ;
}

void  hal_console_init(uint64 base)      { (void)base; /* allow early boot */ }
void  hal_console_putc(char c)           { sbi_putchar(c); /* SBI fallback */ }
int   hal_console_getc(void)             { return -1; }
void  hal_intc_init(uint64 base)         { (void)base; }
void  hal_intc_hart_init(int hart)       { (void)hart; }
void  hal_intc_enable(int irq)           { (void)irq; }
void  hal_intc_enable_hart(int h, int i) { (void)h; (void)i; }
int   hal_intc_claim(void)               { return 0; }
void  hal_intc_complete(int irq)         { (void)irq; }
void  hal_timer_init(void)               { hal_timer_next(1000000); }
uint64 hal_time_read(void)               { return r_time(); }
void  hal_timer_set(uint64 dl)           { sbi_set_timer(dl); }
void  hal_timer_ack(void)                { }
void  hal_timer_next(uint64 iv)          { hal_timer_set(hal_time_read() + iv); }
int   hal_hart_id(void)                  { return (int)r_tp(); }
int   hal_block_init(void)               { return -1; /* no disk yet */ }
void  hal_block_rw(struct buf *b, int w) { (void)b; (void)w; todo("hal_block_rw"); }
void  hal_block_intr(void)               { todo("hal_block_intr"); }
int   hal_block_irq(void)                { return 0; }
