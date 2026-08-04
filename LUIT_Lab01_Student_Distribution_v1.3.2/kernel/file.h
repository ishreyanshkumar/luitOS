/* In-core (in-memory) file-layer objects. On-disk structures live in fs.h. */
#ifndef LUIT_FILE_H
#define LUIT_FILE_H

/* A system-wide open file. Several descriptors (in one process after dup, or
 * in several after fork) may share one struct file - and therefore one offset. */
struct file {
    enum { FD_NONE, FD_PIPE, FD_INODE, FD_DEVICE } type;
    int ref;                  /* reference count, guarded by ftable.lock */
    char readable;
    char writable;
    struct pipe  *pipe;       /* FD_PIPE   */
    struct inode *ip;         /* FD_INODE, FD_DEVICE */
    uint32 off;               /* FD_INODE: byte offset, shared by dup'd fds */
    short major;              /* FD_DEVICE: index into devsw */
};

/* In-core copy of a dinode plus cache bookkeeping.
 * LOCKING: ref and the icache list are guarded by icache.lock (a spinlock);
 * everything below `valid` is guarded by ip->lock (a sleeplock), because
 * reading it may require disk I/O and you cannot sleep holding a spinlock. */
struct inode {
    uint32 dev;
    uint32 inum;
    int ref;
    struct sleeplock lock;
    int valid;               /* has the dinode been read from disk?  */

    uint16 type;             /* copy of the on-disk fields           */
    uint16 major;
    uint16 minor;
    uint16 nlink;
    uint32 size;
    uint32 addrs[NDIRECT + 1];
};

/* Device switch: map a T_DEV major number to read/write functions.
 * Addresses passed here are USER virtual addresses (copyin/copyout inside). */
struct devsw {
    int (*read)(uint64 uaddr, int n);
    int (*write)(uint64 uaddr, int n);
};
extern struct devsw devsw[];
#define CONSOLE 1

#endif
