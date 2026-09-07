/* Lab 10: memory-mapped files.
 *
 * A per-process table of VMAs (mapped regions). mmap records a region and maps
 * nothing; the first access faults into mmap_fault(), which reads the file page
 * in via readi (lazy fault-in). MAP_SHARED writes are flushed back to the file
 * on munmap/msync; MAP_PRIVATE would layer on Lab 5's COW (left as the graded
 * extension). This provides the VMA infrastructure and lazy file-backed faulting;
 * the private-COW and msync-dirty-tracking refinements are the student tasks. */
#include "types.h"
#include "defs.h"
#include "param.h"
#include "file.h"
#include "fs.h"
#include "fcntl.h"

#define NVMA 16
#define MMAP_BASE 0x40000000UL     /* mmap region base (below USER_TOP=0x80000000) */

struct vma {
    int    used;
    uint64 start;      /* user va of the region start */
    uint64 len;        /* length in bytes             */
    int    prot;       /* PROT_READ/WRITE             */
    int    flags;      /* MAP_SHARED / MAP_PRIVATE    */
    struct file *f;    /* backing file                */
    uint64 off;        /* file offset                 */
};

/* per-process VMA tables, indexed by pid slot is overkill; keep it in proc via a
 * pointer would be cleaner, but to stay localized we key on the proc pointer. */
static struct vma vmas[NPROC][NVMA];

/* find the per-proc table by scanning the proc array index */
extern struct proc proc[];
static struct vma *table_for(struct proc *p)
{
    return vmas[p - proc];
}

uint64 mmap(uint64 addr, uint64 len, int prot, int flags, int fd, uint64 off)
{
    struct proc *p = myproc();
    if (len == 0) return -1;
    if (fd < 0 || fd >= NOFILE || p->ofile[fd] == 0) return -1;
    struct file *f = p->ofile[fd];
    if (f->type != FD_INODE) return -1;

    struct vma *tab = table_for(p);
    /* find a free VMA slot and a free virtual range (simple bump within region) */
    uint64 va = MMAP_BASE;
    for (int i = 0; i < NVMA; i++)
        if (tab[i].used && tab[i].start + tab[i].len > va)
            va = PGROUNDUP(tab[i].start + tab[i].len);

    for (int i = 0; i < NVMA; i++) {
        if (!tab[i].used) {
            tab[i].used = 1;
            tab[i].start = va;
            tab[i].len = PGROUNDUP(len);
            tab[i].prot = prot;
            tab[i].flags = flags;
            tab[i].f = filedup(f);       /* hold the file open while mapped */
            tab[i].off = off;
            return va;
        }
    }
    return -1;                            /* no free VMA slot */
}

/* Resolve a fault inside a mapped region: allocate a page, read the file bytes
 * into it, map it. Returns 0 if handled, -1 if the fault is not in any VMA. */
int mmap_fault(struct proc *p, uint64 va)
{
    struct vma *tab = table_for(p);
    va = PGROUNDDOWN(va);
    for (int i = 0; i < NVMA; i++) {
        struct vma *v = &tab[i];
        if (v->used && va >= v->start && va < v->start + v->len) {
            char *mem = palloc();
            if (!mem) return -1;
            memset(mem, 0, PGSIZE);
            /* read the file page (may be short at EOF; the rest stays zero) */
            struct inode *ip = v->f->ip;
            ilock(ip);
            readi(ip, 0, (uint64)mem, v->off + (va - v->start), PGSIZE);
            iunlock(ip);
            int perm = PTE_U | PTE_R;
            if (v->prot & PROT_WRITE) perm |= PTE_W;
            if (mappages(p->pagetable, va, PGSIZE, (uint64)mem, perm) != 0) {
                pfree(mem);
                return -1;
            }
            return 0;
        }
    }
    return -1;
}

/* Write back a MAP_SHARED region's dirty pages and unmap it. */
int munmap(uint64 addr, uint64 len)
{
    struct proc *p = myproc();
    struct vma *tab = table_for(p);
    addr = PGROUNDDOWN(addr);
    for (int i = 0; i < NVMA; i++) {
        struct vma *v = &tab[i];
        if (v->used && addr >= v->start && addr < v->start + v->len) {
            /* write back + unmap each mapped page in the requested range */
            uint64 end = addr + PGROUNDUP(len);
            if (end > v->start + v->len) end = v->start + v->len;
            for (uint64 a = addr; a < end; a += PGSIZE) {
                pte_t *pte = walk(p->pagetable, a, 0);
                if (pte && (*pte & PTE_V)) {
                    if ((v->flags & MAP_SHARED) && (v->prot & PROT_WRITE)) {
                        struct inode *ip = v->f->ip;
                        ilock(ip);
                        writei(ip, 1, a, v->off + (a - v->start), PGSIZE);
                        iunlock(ip);
                    }
                    uvmunmap(p->pagetable, a, 1, 1);
                }
            }
            /* if the whole VMA is gone, release it */
            if (addr == v->start && end == v->start + v->len) {
                fileclose(v->f);
                v->used = 0;
            } else if (addr == v->start) {
                v->start = end; v->off += (end - addr); v->len -= (end - addr);
            } else {
                v->len = addr - v->start;    /* trim the tail */
            }
            return 0;
        }
    }
    return -1;
}

/* Called at exit: unmap everything (write back shared dirty pages). */
void mmap_cleanup(struct proc *p)
{
    struct vma *tab = table_for(p);
    for (int i = 0; i < NVMA; i++) {
        struct vma *v = &tab[i];
        if (v->used) {
            for (uint64 a = v->start; a < v->start + v->len; a += PGSIZE) {
                pte_t *pte = walk(p->pagetable, a, 0);
                if (pte && (*pte & PTE_V)) {
                    if ((v->flags & MAP_SHARED) && (v->prot & PROT_WRITE)) {
                        struct inode *ip = v->f->ip;
                        ilock(ip);
                        writei(ip, 1, a, v->off + (a - v->start), PGSIZE);
                        iunlock(ip);
                    }
                    uvmunmap(p->pagetable, a, 1, 1);
                }
            }
            fileclose(v->f);
            v->used = 0;
        }
    }
}
