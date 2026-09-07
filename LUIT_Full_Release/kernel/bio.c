/* Implementation note. */



















#include "types.h"
#include "defs.h"
#include "hal.h"

static struct {
    struct spinlock lock;
    struct buf buf[NBUF];
    struct buf head;          /* LRU list: head.next = most recent */
} bcache;

void binit(void)
{
    initlock(&bcache.lock, "bcache");
    bcache.head.prev = &bcache.head;
    bcache.head.next = &bcache.head;
    for (struct buf *b = bcache.buf; b < bcache.buf + NBUF; b++) {
        b->next = bcache.head.next;
        b->prev = &bcache.head;
        initsleeplock(&b->lock, "buffer");
        bcache.head.next->prev = b;
        bcache.head.next = b;
    }
}

/* Return a LOCKED buf for (dev, blockno) - cached, or recycled from LRU. */
static struct buf *bget(uint32 dev, uint32 blockno)
{
    acquire(&bcache.lock);

    /* Already cached? */
    for (struct buf *b = bcache.head.next; b != &bcache.head; b = b->next) {
        if (b->dev == dev && b->blockno == blockno) {
            b->refcnt++;
            release(&bcache.lock);
            acquiresleep(&b->lock);
            return b;
        }
    }
    /* Not cached: recycle the LEAST recently used unreferenced buffer. */
    for (struct buf *b = bcache.head.prev; b != &bcache.head; b = b->prev) {
        if (b->refcnt == 0) {
            b->dev = dev;
            b->blockno = blockno;
            b->valid = 0;
            b->refcnt = 1;
            release(&bcache.lock);
            acquiresleep(&b->lock);
            return b;
        }
    }
    panic("bget: no buffers - raise NBUF or find the brelse you forgot");
}

struct buf *bread(uint32 dev, uint32 blockno)
{
    struct buf *b = bget(dev, blockno);
    if (!b->valid) {
        hal_block_rw(b, 0);
        b->valid = 1;
    }
    return b;
}

/* Caller must hold b->lock (i.e. this buf came from bread). */
void bwrite(struct buf *b)
{
    if (!holdingsleep(&b->lock)) panic("bwrite: buf not locked");
    hal_block_rw(b, 1);
}

void brelse(struct buf *b)
{
    if (!holdingsleep(&b->lock)) panic("brelse: buf not locked");
    releasesleep(&b->lock);

    acquire(&bcache.lock);
    b->refcnt--;
    if (b->refcnt == 0) {
        /* Move to the front: most recently used. */
        b->next->prev = b->prev;
        b->prev->next = b->next;
        b->next = bcache.head.next;
        b->prev = &bcache.head;
        bcache.head.next->prev = b;
        bcache.head.next = b;
    }
    release(&bcache.lock);
}
