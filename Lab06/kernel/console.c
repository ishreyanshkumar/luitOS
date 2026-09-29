/* L3/L5 - console: interrupt-driven input, polled output. */
#include "types.h"
#include "defs.h"
#include "hal.h"

#define INBUF 128
static struct {
    struct spinlock lock;
    char  buf[INBUF];
    uint32 r, w, e;      /* read / write / edit indices */
} cons;

void consoleinit(void)
{
    initlock(&cons.lock, "cons");
    /* The console is a DEVICE FILE: mkfs creates /console as a T_DEV inode
     * with major CONSOLE, init opens it as fds 0/1/2, and reads/writes route
     * through this table. No special-case fd numbers anywhere in the kernel. */
    devsw[CONSOLE].read  = consoleread;
    devsw[CONSOLE].write = consolewrite;
}

int consolewrite(uint64 src, int n)
{
    for (int i = 0; i < n; i++) {
        char c;
        /* copyin, not a direct dereference - src is a USER pointer. */
        if (copyin(myproc()->pagetable, &c, src + i, 1) < 0) return -1;
        hal_console_putc(c);
    }
    return n;
}

int consoleread(uint64 dst, int n)
{
    int target = n;
    acquire(&cons.lock);
    while (n > 0) {
        while (cons.r == cons.w) {
            if (myproc()->killed) { release(&cons.lock); return -1; }
            sleep(&cons.r, &cons.lock);
        }
        char c = cons.buf[cons.r++ % INBUF];
        if (c == 4) break;                       /* Ctrl-D */
        if (copyout(myproc()->pagetable, dst, &c, 1) < 0) break;
        dst++; n--;
        if (c == '\n') break;
    }
    release(&cons.lock);
    return target - n;
}

/* Called from the trap handler when the UART raises an interrupt. */
void consoleintr(int c)
{
    acquire(&cons.lock);
    switch (c) {
    case 0x10:                                   /* Ctrl-P: dump processes */
        procdump();
        break;
    case 0x7f: case '\b':                        /* backspace */
        if (cons.e != cons.w) {
            cons.e--;
            hal_console_putc('\b'); hal_console_putc(' '); hal_console_putc('\b');
        }
        break;
    default:
        if (c != 0 && cons.e - cons.r < INBUF) {
            c = (c == '\r') ? '\n' : c;
            hal_console_putc(c);                 /* echo */
            cons.buf[cons.e++ % INBUF] = c;
            if (c == '\n' || c == 4 || cons.e - cons.r == INBUF) {
                cons.w = cons.e;
                wakeup(&cons.r);
            }
        }
        break;
    }
    release(&cons.lock);
}
