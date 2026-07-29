/* One cached disk block. LOCKING: the bcache spinlock guards refcnt and the
 * LRU list; b->lock (a sleeplock) guards data[], valid and disk. You must hold
 * b->lock (i.e. have called bread) to touch data[]. */
#ifndef LUIT_BUF_H
#define LUIT_BUF_H
struct buf {
    int valid;                /* data has been read in                   */
    int disk;                 /* the disk side owns data[] right now     */
    uint32 dev;
    uint32 blockno;
    struct sleeplock lock;
    uint32 refcnt;
    struct buf *prev, *next;  /* Implementation note. */
    uint8 data[BSIZE];
};
#endif
