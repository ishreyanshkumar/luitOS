/* Implementation note. */












#include "types.h"
#include "defs.h"
#include "elf.h"

/* Load one PT_LOAD segment from ip into pt, honouring filesz/memsz + flags. */
static int loadseg(pagetable_t pt, struct inode *ip, struct proghdr *ph)
{
    int perm = PTE_U;
    if (ph->flags & ELF_PROG_FLAG_READ)  perm |= PTE_R;
    if (ph->flags & ELF_PROG_FLAG_WRITE) perm |= PTE_W;
    if (ph->flags & ELF_PROG_FLAG_EXEC)  perm |= PTE_X;

    uint64 start = PGROUNDDOWN(ph->vaddr);
    uint64 end   = PGROUNDUP(ph->vaddr + ph->memsz);

    for (uint64 va = start; va < end; va += PGSIZE) {
        char *mem = palloc();
        if (!mem) return -1;
        memset(mem, 0, PGSIZE);                    /* zero first: this IS the .bss */

        /* the slice of this page that comes from the file (may be empty) */
        uint64 seg_off = (va > ph->vaddr) ? (va - ph->vaddr) : 0;
        uint64 dst_off = (va < ph->vaddr) ? (ph->vaddr - va) : 0;
        if (seg_off < ph->filesz) {
            uint64 n = ph->filesz - seg_off;
            if (n > PGSIZE - dst_off) n = PGSIZE - dst_off;
            if (readi(ip, 0, (uint64)(mem + dst_off),
                      ph->off + seg_off, n) != (int)n) {
                pfree(mem);
                return -1;
            }
        }
        if (mappages(pt, va, PGSIZE, (uint64)mem, perm) != 0) {
            pfree(mem);
            return -1;
        }
    }
    return 0;
}

int exec(char *path, char **argv)
{
    struct inode *ip = namei(path);
    if (ip == 0) return -1;
    ilock(ip);

    struct elfhdr eh;
    pagetable_t newpt = 0;
    uint64 sz = 0;

    if (readi(ip, 0, (uint64)&eh, 0, sizeof(eh)) != sizeof(eh)) goto bad;
    if (eh.magic != ELF_MAGIC) goto bad;              /* reject, do not run */
    if (eh.phnum == 0 || eh.phnum > 16) goto bad;

    if ((newpt = uvmcreate()) == 0) goto bad;

    for (int i = 0; i < eh.phnum; i++) {
        struct proghdr ph;
        if (readi(ip, 0, (uint64)&ph, eh.phoff + i * sizeof(ph),
                  sizeof(ph)) != sizeof(ph)) goto bad;
        if (ph.type != ELF_PROG_LOAD) continue;
        if (ph.memsz < ph.filesz) goto bad;           /* malformed */
        if (ph.vaddr + ph.memsz < ph.vaddr) goto bad; /* overflow  */
        if (ph.vaddr + ph.memsz >= 0x80000000UL) goto bad;  /* into kernel! */

        if (loadseg(newpt, ip, &ph) < 0) goto bad;
        if (ph.vaddr + ph.memsz > sz) sz = ph.vaddr + ph.memsz;
    }
    iunlockput(ip);
    ip = 0;

    /* One guard page, then the user stack. A stack overflow hits the guard
     * and faults, instead of silently eating the program's data. */
    sz = PGROUNDUP(sz);
    uint64 guard = sz;
    uint64 stackbase = guard + PGSIZE;
    char *stack = palloc();
    if (!stack) goto bad;
    memset(stack, 0, PGSIZE);
    if (mappages(newpt, stackbase, PGSIZE, (uint64)stack,
                 PTE_R | PTE_W | PTE_U) != 0) { pfree(stack); goto bad; }
    uint64 sp    = stackbase + PGSIZE;
    uint64 newsz = stackbase + PGSIZE;

    /* Push argv strings onto the new stack, then the pointer array. */
    uint64 ustack[MAXARG + 1];
    int argc = 0;
    struct proc *pp = myproc();
    for (; argv && argv[argc]; argc++) {
        if (argc >= MAXARG) goto bad;
        uint64 len = strlen(argv[argc]) + 1;
        sp -= len;
        sp &= ~7UL;                                   /* keep it 8-aligned */
        if (sp < stackbase) goto bad;
        if (copyout(newpt, sp, argv[argc], len) < 0) goto bad;
        ustack[argc] = sp;
    }
    ustack[argc] = 0;

    sp -= (argc + 1) * sizeof(uint64);
    sp &= ~15UL;                                      /* 16-byte ABI alignment */
    if (sp < stackbase) goto bad;
    if (copyout(newpt, sp, (char *)ustack, (argc + 1) * sizeof(uint64)) < 0) goto bad;

    /* COMMIT POINT. Only now do we destroy the old image - so a failed exec
     * leaves the caller intact and simply returns -1. */
    pagetable_t oldpt = pp->pagetable;
    uint64      oldsz = pp->sz;

    pp->pagetable = newpt;
    pp->sz        = newsz;
    pp->tf->epc   = eh.entry;
    pp->tf->sp    = sp;
    pp->tf->a1    = sp;                               /* argv for main() */

    const char *last = path;
    for (const char *s = path; *s; s++) if (*s == '/') last = s + 1;
    strncpy(pp->name, last, sizeof(pp->name));

    w_satp(MAKE_SATP(pp->pagetable));                 /* we are running on it now */
    sfence_vma();

    uvmfree(oldpt, oldsz);
    return argc;

bad:
    if (newpt) uvmfree(newpt, sz);
    if (ip) iunlockput(ip);
    return -1;
}
