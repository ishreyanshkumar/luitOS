/* THE FILE LAYER - what a file descriptor actually points at.
 *
 *   fd (int, per-process)  ->  p->ofile[fd]  ->  struct file (system-wide)
 *                                                   -> inode, pipe, or device
 *
 * One struct file is SHARED after fork or dup - that is why "cmd > log" in
 * the shell gives parent and child one common offset. The refcount here
 * counts descriptors; the inode's refcount counts struct-file (and namei)
 * holders. Two different counts, two different lifetimes - a favourite
 * viva question.
 *
 * LOCKING: ftable.lock guards ref of every file. Offsets are protected by
 * the inode lock taken inside fileread/filewrite.
 */
#include "types.h"
#include "defs.h"

struct devsw devsw[NDEV];

static struct {
    struct spinlock lock;
    struct file file[NFILE];
} ftable;

void fileinit(void) { initlock(&ftable.lock, "ftable"); }

struct file *filealloc(void)
{
    acquire(&ftable.lock);
    for (struct file *f = ftable.file; f < ftable.file + NFILE; f++) {
        if (f->ref == 0) {
            f->ref = 1;
            release(&ftable.lock);
            return f;
        }
    }
    release(&ftable.lock);
    return 0;
}

struct file *filedup(struct file *f)
{
    acquire(&ftable.lock);
    if (f->ref < 1) panic("filedup");
    f->ref++;
    release(&ftable.lock);
    return f;
}

void fileclose(struct file *f)
{
    acquire(&ftable.lock);
    if (f->ref < 1) panic("fileclose");
    if (--f->ref > 0) { release(&ftable.lock); return; }

    struct file ff = *f;                 /* copy, then free the slot */
    f->ref = 0;
    f->type = FD_NONE;
    release(&ftable.lock);

    if (ff.type == FD_PIPE)
        pipeclose(ff.pipe, ff.writable);
    else if (ff.type == FD_INODE || ff.type == FD_DEVICE)
        iput(ff.ip);
}

int filestat(struct file *f, uint64 uaddr)
{
    if (f->type == FD_INODE || f->type == FD_DEVICE) {
        struct stat st;
        ilock(f->ip);
        stati(f->ip, &st);
        iunlock(f->ip);
        if (copyout(myproc()->pagetable, uaddr, (char *)&st, sizeof(st)) < 0)
            return -1;
        return 0;
    }
    return -1;
}

int fileread(struct file *f, uint64 uaddr, int n)
{
    if (f->readable == 0) return -1;

    if (f->type == FD_PIPE)
        return piperead(f->pipe, uaddr, n);

    if (f->type == FD_DEVICE) {
        if (f->major < 0 || f->major >= NDEV || !devsw[f->major].read) return -1;
        return devsw[f->major].read(uaddr, n);
    }
    if (f->type == FD_INODE) {
        ilock(f->ip);
        int r = readi(f->ip, 1, uaddr, f->off, n);
        if (r > 0) f->off += r;          /* offset update under the inode lock */
        iunlock(f->ip);
        return r;
    }
    panic("fileread");
}

int filewrite(struct file *f, uint64 uaddr, int n)
{
    if (f->writable == 0) return -1;

    if (f->type == FD_PIPE)
        return pipewrite(f->pipe, uaddr, n);

    if (f->type == FD_DEVICE) {
        if (f->major < 0 || f->major >= NDEV || !devsw[f->major].write) return -1;
        return devsw[f->major].write(uaddr, n);
    }
    if (f->type == FD_INODE) {
        ilock(f->ip);
        int r = writei(f->ip, 1, uaddr, f->off, n);
        if (r > 0) f->off += r;
        iunlock(f->ip);
        return (r == n) ? n : -1;        /* short write = disk full = error */
    }
    panic("filewrite");
}
