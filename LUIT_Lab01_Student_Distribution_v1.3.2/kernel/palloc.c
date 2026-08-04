/* L4 - PHYSICAL PAGE ALLOCATOR.
 *
 * Where does memory begin and end? We do NOT hardcode 128 MiB. The device tree
 * told us (fdt.mem_base, fdt.mem_size). Boot with -m 64M or -m 512M and this
 * adapts. That is a graded property.
 *
 * L11 note: every page carries a reference count so copy-on-write can share it.
 * refcount 1 = one owner. pfree() only truly frees when it hits 0.
 */
#include "types.h"
#include "defs.h"

extern char kernel_end[];      /* set by the linker: end of the kernel image */

struct run { struct run *next; };

static struct {
    struct spinlock lock;
    struct run     *freelist;
    uint64          base;      /* first page we manage */
    uint64          top;       /* one past the last    */
    int             nfree;
    uint8          *refcnt;    /* one byte per physical page */
} kmem;

#define PA2IDX(pa) (((uint64)(pa) - kmem.base) >> PGSHIFT)

void palloc_init(void)
{
    initlock(&kmem.lock, "kmem");

    uint64 mem_start = fdt.mem_base;
    uint64 mem_end   = fdt.mem_base + fdt.mem_size;

    /* Reserve: the kernel image, AND the FDT blob itself. Forgetting the FDT is
     * a classic bug - you allocate over the device tree, then reboot mysteriously. */
    /* Reserve the kernel image AND the device-tree blob.
     *
     * CAREFUL - this is a real bug students hit: OpenSBI puts the FDT near the
     * TOP of RAM (on qemu virt, ~0x87e00000). If you "reserve" it by pushing
     * free_start past it, you throw away almost all your memory and end up with
     * a kernel that has 1 MiB and cannot say why. Do NOT skip PAST the blob -
     * skip OVER its pages, and keep everything else.
     */
    uint64 free_start = PGROUNDUP((uint64)kernel_end);
    uint64 fdt_lo = PGROUNDDOWN(fdt.blob);
    uint64 fdt_hi = PGROUNDUP(fdt.blob + fdt.blob_size);

    uint64 npages = (mem_end - free_start) >> PGSHIFT;

    /* One refcount byte per page (L11, copy-on-write). Carve it out of the
     * front of free memory - which is below the FDT, so this is safe. */
    uint64 refbytes = PGROUNDUP(npages);
    kmem.refcnt = (uint8 *)free_start;
    memset(kmem.refcnt, 0, refbytes);
    free_start += refbytes;

    kmem.base = free_start;
    kmem.top  = mem_end;
    kmem.freelist = 0;
    kmem.nfree = 0;

    for (uint64 p = kmem.base; p + PGSIZE <= kmem.top; p += PGSIZE) {
        if (p >= fdt_lo && p < fdt_hi)      /* the device tree lives here */
            continue;                       /* never hand this page out    */
        struct run *r = (struct run *)p;
        kmem.refcnt[PA2IDX(p)] = 0;
        r->next = kmem.freelist;
        kmem.freelist = r;
        kmem.nfree++;
    }
    printf("palloc: RAM %p..%p, managing %d free pages (%d MiB)\n",
           mem_start, mem_end, kmem.nfree, (kmem.nfree * PGSIZE) >> 20);
}

void *palloc(void)
{
    acquire(&kmem.lock);
    struct run *r = kmem.freelist;
    if (r) {
        kmem.freelist = r->next;
        kmem.nfree--;
        kmem.refcnt[PA2IDX(r)] = 1;
    }
    release(&kmem.lock);

    if (r)
        memset((void *)r, 5, PGSIZE);   /* poison: catch use-before-init */
    return (void *)r;
}

void palloc_ref_inc(void *pa)
{
    acquire(&kmem.lock);
    kmem.refcnt[PA2IDX(pa)]++;
    release(&kmem.lock);
}

int palloc_ref_get(void *pa)
{
    acquire(&kmem.lock);
    int n = kmem.refcnt[PA2IDX(pa)];
    release(&kmem.lock);
    return n;
}

void pfree(void *pa)
{
    if (((uint64)pa % PGSIZE) != 0 || (uint64)pa < kmem.base || (uint64)pa >= kmem.top)
        panic("pfree: bad pointer");

    acquire(&kmem.lock);
    uint64 i = PA2IDX(pa);
    if (kmem.refcnt[i] < 1)
        panic("pfree: double free / refcount underflow");

    if (--kmem.refcnt[i] > 0) {          /* still shared (COW) - not really free */
        release(&kmem.lock);
        return;
    }
    memset(pa, 1, PGSIZE);               /* poison: catch use-after-free */
    struct run *r = (struct run *)pa;
    r->next = kmem.freelist;
    kmem.freelist = r;
    kmem.nfree++;
    release(&kmem.lock);
}

int palloc_free_count(void)
{
    acquire(&kmem.lock);
    int n = kmem.nfree;
    release(&kmem.lock);
    return n;
}
