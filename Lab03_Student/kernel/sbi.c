/* SBI calls - the ONLY way an S-mode kernel talks to M-mode firmware (OpenSBI). */
#include "types.h"
#include "defs.h"

struct sbiret { long error; long value; };

static struct sbiret sbi_call(long eid, long fid, long a0, long a1, long a2)
{
    register long r_a0 asm("a0") = a0;
    register long r_a1 asm("a1") = a1;
    register long r_a2 asm("a2") = a2;
    register long r_a6 asm("a6") = fid;
    register long r_a7 asm("a7") = eid;
    asm volatile ("ecall"
                  : "+r"(r_a0), "+r"(r_a1)
                  : "r"(r_a2), "r"(r_a6), "r"(r_a7)
                  : "memory");
    struct sbiret ret = { r_a0, r_a1 };
    return ret;
}

/* Early console, used before the device tree has told us where the UART is.
 * NOTE: the LEGACY console extension (EID 0x01) is deprecated and is disabled
 * in recent OpenSBI. Use DBCN (Debug Console, EID 0x4442434E) and fall back to
 * legacy only if DBCN is unavailable. Students hit this: an early sbi_putchar
 * that silently does nothing makes a boot panic invisible. */
void sbi_putchar(int c)
{
    unsigned char ch = (unsigned char)c;
    /* DBCN console_write_byte = EID 0x4442434E, FID 2 */
    struct sbiret r = sbi_call(0x4442434E, 2, ch, 0, 0);
    if (r.error != 0)
        sbi_call(0x01, 0, c, 0, 0);        /* legacy putchar */
}

/* TIME extension: set the next timer interrupt (absolute time). */
void sbi_set_timer(uint64 stime) { sbi_call(0x54494D45, 0, stime, 0, 0); }

/* HSM extension: start a secondary hart at `addr` (L9, SMP). */
long sbi_hart_start(uint64 hartid, uint64 addr, uint64 opaque)
{
    return sbi_call(0x48534D, 0, hartid, addr, opaque).error;
}
