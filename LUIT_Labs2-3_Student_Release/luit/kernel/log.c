/* Lab 11: write-ahead logging for LuitFS (crash consistency).
 *
 * A filesystem operation that touches several blocks must be atomic across a
 * crash: either all its writes survive or none do. The log makes this work:
 *
 *   begin_op()         start a transaction
 *   log_write(bp)      instead of writing bp home, remember it belongs to the txn
 *   end_op()           COMMIT: (1) copy all txn blocks into the log region,
 *                      (2) write the commit header (block count + home blocks),
 *                      (3) install the blocks to their home locations,
 *                      (4) clear the header.
 *
 * A crash before step 2 = the header shows 0 blocks, recovery does nothing, the
 * filesystem is untouched. A crash after step 2 = recovery replays the logged
 * blocks to their homes. The commit header write is the atomic commit point.
 */
#include "types.h"
#include "defs.h"
#include "param.h"
#include "fs.h"
#include "buf.h"

#define MAXOP 15                 /* max blocks a single transaction may write */

struct logheader {
    int n;                       /* number of blocks in the committed txn (0 = none) */
    int block[30];               /* home block numbers, block[i] <- logstart+1+i */
};

static struct {
    struct spinlock lock;
    int start;                   /* logstart from superblock */
    int size;                    /* nlog */
    int outstanding;             /* begin_op calls not yet ended */
    int committing;
    struct logheader lh;         /* the in-memory header being built */
} log;

extern struct superblock sb;

static void install_trans(void);
static void write_log(void);
static void write_head(void);
static void read_head(void);
static void recover(void);

void log_init(int dev)
{
    initlock(&log.lock, "log");
    log.start = sb.logstart;
    log.size  = sb.nlog;
    log.lh.n  = 0;
    recover();                   /* replay any committed txn left by a crash */
}

/* recovery on mount: if the header shows committed blocks, install them. */
static void recover(void)
{
    read_head();
    install_trans();             /* replay */
    log.lh.n = 0;
    write_head();                /* clear */
}

void begin_op(void)
{
    acquire(&log.lock);
    while (log.committing || log.lh.n + (log.outstanding + 1) * MAXOP > log.size - 1)
        sleep(&log, &log.lock);
    log.outstanding++;
    release(&log.lock);
}

void end_op(void)
{
    int do_commit = 0;
    acquire(&log.lock);
    log.outstanding--;
    if (log.outstanding == 0) { do_commit = 1; log.committing = 1; }
    else wakeup(&log);
    release(&log.lock);

    if (do_commit) {
        /* commit protocol */
        write_log();             /* 1. blocks -> log region */
        write_head();            /* 2. commit point: header on disk */
        install_trans();         /* 3. log -> home */
        log.lh.n = 0;
        write_head();            /* 4. clear */
        acquire(&log.lock);
        log.committing = 0;
        wakeup(&log);
        release(&log.lock);
    }
}

/* Lab 11 crash-injection hook: commit the transaction to disk (log + header)
 * but do NOT install and do NOT clear - as if power was lost right after the
 * commit point. The next mount's recover() must replay it. */
void log_commit_only(void)
{
    write_log();
    write_head();
    /* deliberately no install_trans(), no header clear */
}

/* Called instead of bwrite: record that this block is part of the txn. */
void log_write(struct buf *b)
{
    acquire(&log.lock);
    int i;
    for (i = 0; i < log.lh.n; i++)
        if (log.lh.block[i] == (int)b->blockno) break;   /* absorb duplicate */
    log.lh.block[i] = b->blockno;
    if (i == log.lh.n) log.lh.n++;
    b->refcnt++;                 /* pin in cache until installed */
    release(&log.lock);
}

/* copy each txn block from the cache into the log region on disk */
static void write_log(void)
{
    for (int t = 0; t < log.lh.n; t++) {
        struct buf *to   = bread(1, log.start + 1 + t);      /* log slot */
        struct buf *from = bread(1, log.lh.block[t]);        /* cached block */
        memmove(to->data, from->data, BSIZE);
        bwrite(to);
        brelse(from);
        brelse(to);
    }
}

/* install: copy logged blocks from the log region to their home locations */
static void install_trans(void)
{
    for (int t = 0; t < log.lh.n; t++) {
        struct buf *from = bread(1, log.start + 1 + t);      /* from log */
        struct buf *to   = bread(1, log.lh.block[t]);        /* home block */
        memmove(to->data, from->data, BSIZE);
        bwrite(to);
        brelse(from);
        brelse(to);
    }
}

/* the header lives in the first log block; its n field is the commit flag */
static void write_head(void)
{
    struct buf *b = bread(1, log.start);
    struct logheader *hb = (struct logheader *)b->data;
    hb->n = log.lh.n;
    for (int i = 0; i < log.lh.n; i++) hb->block[i] = log.lh.block[i];
    bwrite(b);
    brelse(b);
}

static void read_head(void)
{
    struct buf *b = bread(1, log.start);
    struct logheader *hb = (struct logheader *)b->data;
    log.lh.n = hb->n;
    for (int i = 0; i < log.lh.n && i < 30; i++) log.lh.block[i] = hb->block[i];
    brelse(b);
}
