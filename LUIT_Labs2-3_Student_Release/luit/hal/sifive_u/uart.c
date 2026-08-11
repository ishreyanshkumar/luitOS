/* Lab 12: SiFive UART (SiFive FU540 / QEMU sifive_u board).
 *
 * A DIFFERENT device from the qemu virt's NS16550A: 32-bit memory-mapped
 * registers, a txdata register whose high bit signals "FIFO full", and an
 * rxdata register whose high bit signals "empty". This is the whole reason the
 * HAL exists: the kernel core never changes, only this backend does. */
#include "types.h"
#include "hal.h"

static volatile uint32 *uart;   /* base from the device tree */

#define TXDATA  0   /* [31]=full, [7:0]=byte to send   */
#define RXDATA  1   /* [31]=empty, [7:0]=received byte */
#define TXCTRL  2   /* [0]=txen                        */
#define RXCTRL  3   /* [0]=rxen                        */
#define IE      4   /* interrupt enable                */

void hal_console_init(uint64 uart_base)
{
    uart = (volatile uint32 *)uart_base;
    uart[TXCTRL] = 1;             /* enable transmit */
    uart[RXCTRL] = 1;             /* enable receive  */
    uart[IE]     = 2;             /* rx interrupt enable (bit 1 = rxwm) */
}

void hal_console_putc(char c)
{
    if (!uart) return;
    while (uart[TXDATA] & 0x80000000U)   /* wait while FIFO full */
        ;
    uart[TXDATA] = (uint32)(uint8)c;
}

int hal_console_getc(void)
{
    if (!uart) return -1;
    uint32 r = uart[RXDATA];
    if (r & 0x80000000U) return -1;      /* empty */
    return (int)(r & 0xff);
}
