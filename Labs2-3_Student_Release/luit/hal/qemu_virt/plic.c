/* L5 - PLIC (platform-level interrupt controller). Base address from the FDT. */
#include "types.h"
#include "hal.h"
#include "riscv.h"

static uint64 plic;

/* Per-hart S-mode enable / priority-threshold / claim registers. */
#define PLIC_PRIORITY(irq)   (plic + (irq) * 4)
#define PLIC_SENABLE(h)      (plic + 0x2080 + (h) * 0x100)
#define PLIC_STHRESHOLD(h)   (plic + 0x201000 + (h) * 0x2000)
#define PLIC_SCLAIM(h)       (plic + 0x201004 + (h) * 0x2000)

void hal_intc_init(uint64 plic_base) { plic = plic_base; }

void hal_intc_enable(int irq)
{
    if (!plic) return;
    *(volatile uint32 *)PLIC_PRIORITY(irq) = 1;   /* priority 0 = never fire */
}

void hal_intc_hart_init(int hart)
{
    if (!plic) return;
    *(volatile uint32 *)PLIC_STHRESHOLD(hart) = 0; /* accept any priority > 0 */
}

/* Enable irq for this hart (must be called after hal_intc_enable). */
void hal_intc_enable_hart(int hart, int irq)
{
    if (!plic) return;
    volatile uint32 *en = (volatile uint32 *)PLIC_SENABLE(hart);
    en[irq / 32] |= (1u << (irq % 32));
}

int hal_intc_claim(void)
{
    if (!plic) return 0;
    return *(volatile uint32 *)PLIC_SCLAIM(hal_hart_id());
}

void hal_intc_complete(int irq)
{
    if (!plic) return;
    *(volatile uint32 *)PLIC_SCLAIM(hal_hart_id()) = irq;
}

int hal_hart_id(void) { return (int)r_tp(); }

int plic_dbg(int which)
{
    if (which == 0) return *(volatile uint32 *)PLIC_PRIORITY(10);
    return *(volatile uint32 *)PLIC_SENABLE(0);
}
