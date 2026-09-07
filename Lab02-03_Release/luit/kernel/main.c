/* Boot sequence. Read this top to bottom - it is the map of the whole kernel. */
#include "types.h"
#include "defs.h"
#include "hal.h"
extern int console_ready;
extern char etext[];

volatile static int started = 0;
volatile static int boot_hart = -1;   /* Lab 12: elected at runtime, not assumed 0 */

extern void _entry(void);

/* Secondary harts land here via SBI HSM. */
static void secondary_main(void)
{
    kvminithart();          /* same kernel page table */
    trapinit_hart();        /* own stvec, own timer, own PLIC context */
    printf("hart %d: online\n", hal_hart_id());
    scheduler();            /* never returns */
}

void start(uint64 hartid, uint64 fdt_pa)
{
    /* Lab 12: elect the boot hart at runtime. The boot hart is whichever one
     * the firmware entered first (hart 0 on qemu virt, hart 1 on sifive_u where
     * hart 0 is a low-power monitor). The first arrival wins the CAS. */
    if (boot_hart == -1 &&
        __sync_bool_compare_and_swap(&boot_hart, -1, (int)hartid)) {
        /* --- boot hart --- */

        /* BEFORE anything else, ask the firmware what hardware we have.
         * Until fdt_init() runs we know nothing about this board - and we do
         * not pretend to. Use SBI's console for the very first messages. */
        fdt_init(fdt_pa);

        /* Report what we discovered BEFORE we trust it - these lines go out over
         * the SBI console, so they are visible even if the UART base is wrong. */
        printf("\n");
        printf("=========================================\n");
        printf("  BrahmaputraOS / kernel Luit\n");
        printf("  IIT Guwahati - CS3106L\n");
        printf("=========================================\n");
        printf("fdt   : blob at %p (%d bytes)\n", fdt.blob, fdt.blob_size);
        printf("uart  : %p  (discovered, not hardcoded)\n", fdt.uart_base);
        printf("plic  : %p\n", fdt.plic_base);
        printf("memory: %p + %d MiB\n", fdt.mem_base, fdt.mem_size >> 20);
        printf("harts : %d\n", fdt.ncpu);

        /* Now switch to our own UART driver. */
        hal_console_init(fdt.uart_base);
        hal_intc_init(fdt.plic_base);
        console_ready = 1;

        palloc_init();
        printfinit();       /* locked printf, now that we have locks + memory */
        procinit();
        trace_init();      /* Lab 2 */
        futex_init();      /* Lab 6 */
        kvminit();
        kvminithart();      /* paging ON for this hart */

        /* MMIO is now behind the page table at its high alias - re-point the
         * drivers at the virtual addresses. This is why the HAL takes a base
         * address as an argument instead of hardcoding one. */
        console_ready = 0;                    /* SBI console while we re-point */
        hal_console_init(mmio_alias(fdt.uart_base));
        console_ready = 1;
        hal_intc_init(mmio_alias(fdt.plic_base));

        consoleinit();      /* console device (major CONSOLE)         */
        binit();            /* buffer cache                           */
        iinit();            /* inode cache                            */
        fileinit();         /* system-wide open-file table            */
        if (hal_block_init() < 0)
            panic("no block device: did you forget -drive/-device? (make qemu adds it)");
        trapinit_hart();    /* traps, timer, PLIC (incl. the disk irq) */
        userinit();         /* the first user process                 */

        printf("hart %d: online (boot)\n", (int)hartid);
        __sync_synchronize();
        started = 1;

        /* L9: SMP. Start every OTHER hart the device tree told us about.
         * We do not assume 1. We do not assume 4. We ask. */
        for (int i = 0; i < fdt.ncpu; i++) {
            if (i == boot_hart) continue;        /* skip ourselves */
            long err = sbi_hart_start(i, (uint64)_entry, 0);
            if (err) printf("hart %d: failed to start (sbi err %d)\n", i, err);
        }

        scheduler();
    } else {
        /* --- secondary harts --- */
        while (started == 0)
            ;
        __sync_synchronize();
        secondary_main();
    }
}
