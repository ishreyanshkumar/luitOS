/* L3 - FLATTENED DEVICE TREE PARSER.
 *
 * This is the file that separates a real kernel from a toy. We do NOT #define
 * UART0 0x10000000. We ask the firmware what hardware exists.
 *
 * FDT layout:  [header][mem reservation block][structure block][strings block]
 * ALL 32-bit fields are BIG-ENDIAN. This is the bug every student hits once.
 */
#include "types.h"
#include "defs.h"

#define FDT_MAGIC       0xd00dfeed
#define FDT_BEGIN_NODE  1
#define FDT_END_NODE    2
#define FDT_PROP        3
#define FDT_NOP         4
#define FDT_END         9

struct fdt_header {
    uint32 magic, totalsize, off_dt_struct, off_dt_strings;
    uint32 off_mem_rsvmap, version, last_comp_version;
    uint32 boot_cpuid_phys, size_dt_strings, size_dt_struct;
};

/* The FDT is big-endian; RISC-V is little-endian. Swap on every read. */
static uint32 be32(uint32 x) {
    return ((x & 0xFF) << 24) | ((x & 0xFF00) << 8) |
           ((x >> 8) & 0xFF00) | ((x >> 24) & 0xFF);
}
static uint64 be64(const uint32 *p) {
    return ((uint64)be32(p[0]) << 32) | be32(p[1]);
}

#define MAXDEPTH 16

struct fdt_info fdt;                 /* what we discovered about this board */
static const char *strings;          /* strings block base */

static int streq(const char *a, const char *b) {
    while (*a && *a == *b) { a++; b++; }
    return *a == *b;
}
/* does `list` (a NUL-separated string list of length len) contain `want`? */
static int strlist_has(const char *list, int len, const char *want) {
    int i = 0;
    while (i < len) {
        if (streq(&list[i], want)) return 1;
        while (i < len && list[i]) i++;
        i++;
    }
    return 0;
}
/* does name start with prefix? (e.g. node "uart@10000000" vs prefix "uart@") */
static int startswith(const char *s, const char *pre) {
    while (*pre) { if (*s++ != *pre++) return 0; }
    return 1;
}

/* Parse the whole tree.
 *
 * TWO BUGS EVERY STUDENT HITS HERE - both are in this function, fixed:
 *
 * 1. ENDIANNESS. Every 32-bit field in the FDT is BIG-endian; RISC-V is little.
 *    Read one without be32() and you get garbage that looks almost plausible.
 *
 * 2. PROPERTY ORDER. You cannot assume `compatible` appears BEFORE `reg` inside
 *    a node - the spec does not require it, and on qemu virt it often does not.
 *    A parser that sets a "pending" flag on compatible and consumes it on the
 *    next reg will silently attach one node's address to a DIFFERENT device.
 *    Instead: buffer BOTH properties for the current node, and only decide what
 *    the node is when the node ENDS.
 *
 * Also: a node's `reg` is decoded with its PARENT's #address-cells/#size-cells,
 * not its own. We keep a small stack of them.
 */
void fdt_init(uint64 fdt_pa)
{
    struct fdt_header *h = (struct fdt_header *)fdt_pa;

    if (be32(h->magic) != FDT_MAGIC)
        panic("fdt: bad magic - is a1 really the device tree?");

    strings = (const char *)(fdt_pa + be32(h->off_dt_strings));
    const uint32 *p = (const uint32 *)(fdt_pa + be32(h->off_dt_struct));

    fdt.blob = fdt_pa;
    fdt.blob_size = be32(h->totalsize);
    fdt.ncpu = 0;
    fdt.uart_base = 0; fdt.plic_base = 0; fdt.uart_irq = 0;
    fdt.nvirtio = 0;
    fdt.mem_base = 0;  fdt.mem_size = 0;

    /* #address-cells / #size-cells, one slot per depth. Defaults per spec. */
    int ac[MAXDEPTH], sc[MAXDEPTH];
    ac[0] = 2; sc[0] = 2;

    int depth = 0;
    int cpus_depth = -1;

    /* properties buffered for the node we are currently inside */
    int    kind = PEND_NONE;
    int    have_reg = 0;
    uint64 reg_base = 0, reg_size = 0;
    int    have_irq = 0, irq = 0;

    for (;;) {
        uint32 tok = be32(*p++);

        if (tok == FDT_END) break;
        if (tok == FDT_NOP) continue;

        if (tok == FDT_BEGIN_NODE) {
            const char *name = (const char *)p;
            int len = 0; while (name[len]) len++;
            p += (len + 4) / 4;                 /* NUL-terminated, 4-byte padded */

            depth++;
            if (depth >= MAXDEPTH) panic("fdt: tree too deep");
            ac[depth] = ac[depth - 1];          /* inherit until told otherwise */
            sc[depth] = sc[depth - 1];

            /* start a fresh property buffer for this node */
            kind = PEND_NONE; have_reg = 0; reg_base = 0; reg_size = 0;
            have_irq = 0; irq = 0;

            if (streq(name, "cpus")) cpus_depth = depth;
            if (cpus_depth > 0 && depth == cpus_depth + 1 && startswith(name, "cpu@"))
                fdt.ncpu++;
            continue;
        }

        if (tok == FDT_END_NODE) {
            /* NOW we know everything about this node - decide what it was. */
            if (have_reg && kind != PEND_NONE) {
                switch (kind) {
                case PEND_UART:
                    if (!fdt.uart_base) {
                        fdt.uart_base = reg_base;
                        if (have_irq) fdt.uart_irq = irq;
                    }
                    break;
                case PEND_PLIC:   if (!fdt.plic_base) fdt.plic_base = reg_base; break;
                /* qemu virt exposes 8 virtio-mmio slots, and the FDT cannot
                 * tell us which one has a device behind it. Record ALL of
                 * them; hal_block_init() probes each slot's magic/deviceID. */
                case PEND_VIRTIO:
                    if (fdt.nvirtio < FDT_MAX_VIRTIO) {
                        fdt.virtio_base[fdt.nvirtio] = reg_base;
                        fdt.virtio_irq[fdt.nvirtio]  = have_irq ? irq : 0;
                        fdt.nvirtio++;
                    }
                    break;
                case PEND_MEM:    fdt.mem_base = reg_base; fdt.mem_size = reg_size; break;
                }
            }
            if (depth == cpus_depth) cpus_depth = -1;
            depth--;
            kind = PEND_NONE; have_reg = 0;
            continue;
        }

        if (tok == FDT_PROP) {
            uint32 len     = be32(*p++);
            uint32 nameoff = be32(*p++);
            const char *pname = &strings[nameoff];
            const uint32 *val = p;
            p += (len + 3) / 4;                 /* properties are 4-byte aligned */

            if (streq(pname, "#address-cells")) {
                ac[depth] = be32(val[0]);
            } else if (streq(pname, "#size-cells")) {
                sc[depth] = be32(val[0]);
            } else if (streq(pname, "compatible")) {
                const char *c = (const char *)val;
                /* Match on `compatible` - NEVER on the node name. A board is
                 * free to call its UART anything; `compatible` is the contract. */
                if (strlist_has(c, len, "ns16550a") || strlist_has(c, len, "ns16550") ||
                    strlist_has(c, len, "sifive,uart0"))   /* Lab 12: sifive_u board */
                    kind = PEND_UART;
                else if (strlist_has(c, len, "riscv,plic0") ||
                         strlist_has(c, len, "sifive,plic-1.0.0"))
                    kind = PEND_PLIC;
                else if (strlist_has(c, len, "virtio,mmio"))
                    kind = PEND_VIRTIO;
            } else if (streq(pname, "device_type")) {
                if (strlist_has((const char *)val, len, "memory"))
                    kind = PEND_MEM;
            } else if (streq(pname, "interrupts")) {
                /* First cell = PLIC source number (qemu virt uses plain
                 * one-cell specifiers for uart and virtio). */
                if (len >= 4) { irq = be32(val[0]); have_irq = 1; }
            } else if (streq(pname, "reg")) {
                /* Decode with the PARENT's cell counts. */
                int pac = ac[depth - 1];
                int psc = sc[depth - 1];
                if (pac == 2)      reg_base = be64(val);
                else if (pac == 1) reg_base = be32(val[0]);
                else               reg_base = 0;

                if (psc == 2)      reg_size = be64(&val[pac]);
                else if (psc == 1) reg_size = be32(val[pac]);
                else               reg_size = 0;
                have_reg = 1;
            }
            continue;
        }
        panic("fdt: unknown token in structure block");
    }

    if (fdt.ncpu == 0) fdt.ncpu = 1;
    if (fdt.ncpu > NCPU) fdt.ncpu = NCPU;
    if (!fdt.uart_base) panic("fdt: no console found on this board");
    if (!fdt.mem_size)  panic("fdt: no memory node");
}
