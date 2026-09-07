/* Implementation note. */
#include <stdarg.h>
#include "types.h"
#include "defs.h"
#include "hal.h"

static struct spinlock pr_lock;
static int pr_locking = 0;      /* off until printfinit(); panic turns it off */

static char digits[] = "0123456789abcdef";

/* Before the UART driver exists (i.e. before the device tree has told us where
 * the UART is), fall back to OpenSBI's console. This is why a panic inside
 * fdt_init() is still visible - a silent early panic is a nightmare to debug. */
int console_ready = 0;
static void putc(char c) { if (console_ready) hal_console_putc(c); else sbi_putchar(c); }

static void printint(long long xx, int base, int sign)
{
    char buf[24];
    int i = 0;
    unsigned long long x;

    if (sign && xx < 0) { x = -xx; } else { sign = 0; x = xx; }
    do { buf[i++] = digits[x % base]; } while ((x /= base) != 0);
    if (sign) buf[i++] = '-';
    while (--i >= 0) putc(buf[i]);
}

static void printptr(uint64 x)
{
    putc('0'); putc('x');
    for (int i = 0; i < 16; i++, x <<= 4)
        putc(digits[x >> 60]);
}

void printf(const char *fmt, ...)
{
    va_list ap;
    int locking = pr_locking;
    if (locking) acquire(&pr_lock);

    va_start(ap, fmt);
    for (int i = 0; fmt[i]; i++) {
        char c = fmt[i];
        if (c != '%') { putc(c); continue; }
        c = fmt[++i];
        if (!c) break;
        switch (c) {
        case 'd': printint(va_arg(ap, int), 10, 1); break;
        case 'l': printint(va_arg(ap, uint64), 10, 0); break;
        case 'u': printint(va_arg(ap, uint64), 10, 0); break;
        case 'x': printint(va_arg(ap, uint64), 16, 0); break;
        case 'p': printptr(va_arg(ap, uint64)); break;
        case 'c': putc((char)va_arg(ap, int)); break;
        case 's': {
            const char *s = va_arg(ap, const char *);
            if (!s) s = "(null)";
            while (*s) putc(*s++);
            break;
        }
        case '%': putc('%'); break;
        default:  putc('%'); putc(c); break;
        }
    }
    va_end(ap);
    if (locking) release(&pr_lock);
}

void printfinit(void) { initlock(&pr_lock, "pr"); pr_locking = 1; }

void panic(const char *s)
{
    pr_locking = 0;                       /* never deadlock inside a panic */
    printf("\n=== KERNEL PANIC (hart %d) ===\n", hal_hart_id());
    printf("  %s\n", s);
    printf("  sepc   = %p\n", r_sepc());
    printf("  scause = %p\n", r_scause());
    printf("  stval  = %p\n", r_stval());
    printf("  satp   = %p\n", r_satp());
    printf("=============================\n");
    for (;;) asm volatile("wfi");
}
