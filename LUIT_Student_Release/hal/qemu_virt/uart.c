/* Implementation note. */


#include "types.h"
#include "hal.h"

static volatile uint8 *uart;   /* set from the device tree at init */

#define RHR 0   /* receive holding  (read)  */
#define THR 0   /* transmit holding (write) */
#define IER 1   /* interrupt enable         */
#define FCR 2   /* FIFO control             */
#define LCR 3   /* line control             */
#define LSR 5   /* line status              */
#define LSR_RX_READY  (1 << 0)
#define LSR_TX_IDLE   (1 << 5)

void hal_console_init(uint64 uart_base)
{
    uart = (volatile uint8 *)uart_base;
    uart[IER] = 0x00;              /* interrupts off while we configure */
    uart[LCR] = 0x80;              /* DLAB=1: divisor latch visible     */
    uart[0]   = 0x03;              /* divisor low: 38.4K                */
    uart[1]   = 0x00;              /* divisor high                      */
    uart[LCR] = 0x03;              /* DLAB=0, 8 bits, no parity, 1 stop */
    uart[FCR] = 0x07;              /* enable + clear FIFOs              */
    uart[IER] = 0x01;              /* receive interrupts on             */
}

void hal_console_putc(char c)
{
    if (!uart) { return; }
    while ((uart[LSR] & LSR_TX_IDLE) == 0)   /* wait for the holding reg */
        ;
    uart[THR] = c;
}

int hal_console_getc(void)
{
    if (!uart) return -1;
    if (uart[LSR] & LSR_RX_READY)
        return uart[RHR];
    return -1;
}
