/* Implementation note. */







#ifndef LUIT_HAL_H
#define LUIT_HAL_H
#include "types.h"

/* Console. hal_console_init() is called with the base address the DEVICE TREE
 * reported - the HAL never invents it. */
void  hal_console_init(uint64 uart_base);
void  hal_console_putc(char c);
int   hal_console_getc(void);          /* -1 if no character ready */

/* Interrupt controller (PLIC). */
void  hal_intc_init(uint64 plic_base);
void  hal_intc_hart_init(int hart);
void  hal_intc_enable(int irq);
int   hal_intc_claim(void);
void  hal_intc_complete(int irq);

/* Timer. The kernel programs DEADLINES (absolute times), the HAL delivers
 * them. On QEMU/OpenSBI this goes through the SBI TIME extension: the CLINT
 * is an M-mode device that firmware owns, and S-mode must not touch it.
 * hal_timer_ack() exists because some boards need an explicit acknowledge;
 * with SBI the next hal_timer_set() implicitly clears the pending bit. */
void    hal_timer_init(void);
uint64  hal_time_read(void);
void    hal_timer_set(uint64 deadline);
void    hal_timer_ack(void);
void    hal_timer_next(uint64 interval);   /* convenience: set(read()+interval) */

/* Block device. The backend probes the board (on qemu_virt: the virtio-mmio
 * slots the FDT reported), owns DMA and rings, and completes requests from
 * its interrupt handler. `write` nonzero = write b->data to disk.
 * hal_block_rw SLEEPS until completion - callers hold b->lock (a sleeplock),
 * never a spinlock. */
struct buf;
int   hal_block_init(void);        /* 0 on success, -1 if no disk found  */
void  hal_block_rw(struct buf *b, int write);
void  hal_block_intr(void);        /* called by devintr on hal_block_irq */
int   hal_block_irq(void);         /* PLIC source of the block device, 0 = none */

/* Identity */
int   hal_hart_id(void);

#endif
