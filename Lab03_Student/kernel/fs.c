/* LUITFS - the persistent filesystem. On-disk format: fs.h and docs/LUITFS.md.
 *
 * LAYER MAP (bottom to top):
 *   hal_block_rw     one block to/from the disk           (the HAL's virtio_blk.c)
 *   bread/bwrite     cached, locked block access          (bio.c)
 *   balloc/bfree     data-block allocation  (data bitmap) (here)
 *   ialloc..itrunc   inodes                 (inode bitmap)(here)
 *   readi/writei     byte-granularity file I/O            (here)
 *   dirlookup/link   directories                          (here)
 *   namei            path -> inode                        (here)
 *
 * CRASH BEHAVIOUR, stated honestly: LuitFS v1 is persistent but NOT
 * crash-consistent. Writes go straight through bwrite in a careful order
 * (allocate before reference, zero before expose), which limits but does not
 * eliminate damage from power loss mid-operation. Lab 11 adds a write-ahead
 * journal (the superblock reserves `nlog` for it) and randomized crash tests.
 *
 * LOCK ORDER (deadlock discipline - violating this hangs the machine):
 *   parent-directory inode -> child inode -> buffer(s)
 * Never hold two sibling inode locks. Never acquire an inode lock while
 * holding a buffer lock.
 */
#include "types.h"
#include "defs.h"
#include "hal.h"

struct superblock sb;

static void readsb(int dev)
{
    struct buf *bp = bread(dev, 1);
    memmove(&sb, bp->data, sizeof(sb));
    brelse(bp);
}

void fsinit(int dev)
{
    readsb(dev);
    if (sb.magic != LUITFS_MAGIC) panic("fsinit: not a LuitFS disk (bad magic)");
    if (sb.version != LUITFS_VERSION) panic("fsinit: LuitFS version mismatch");
    printf("luitfs: %d blocks, %d inodes, data at block %d\n",
           sb.size, sb.ninodes, sb.datastart);
}

/* Zero a disk block. A freshly allocated block MUST be zeroed before any
 * inode can point at it, or a file could read another file's stale secrets. */
static void bzero_disk(int dev, int bno)
{
    struct buf *bp = bread(dev, bno);
    memset(bp->data, 0, BSIZE);
    bwrite(bp);
    brelse(bp);
}

/* ---------- data-block allocator (data bitmap) ---------- */

/* One bit per block of the whole image; mkfs pre-marks the metadata region. */
static uint32 balloc(uint32 dev)
{
    for (uint32 b = 0; b < sb.size; b += BPB) {
        struct buf *bp = bread(dev, DBBLOCK(b, sb));
        for (uint32 bi = 0; bi < BPB && b + bi < sb.size; bi++) {
            int m = 1 << (bi % 8);
            if ((bp->data[bi / 8] & m) == 0) {
                bp->data[bi / 8] |= m;              /* claim it... */
                bwrite(bp);                         /* ...ON DISK, before use */
                brelse(bp);
                bzero_disk(dev, b + bi);
                return b + bi;
            }
        }
        brelse(bp);
    }
    printf("luitfs: out of data blocks\n");
    return 0;
}

static void bfree(int dev, uint32 b)
{
    struct buf *bp = bread(dev, DBBLOCK(b, sb));
    uint32 bi = b % BPB;
    int m = 1 << (bi % 8);
    if ((bp->data[bi / 8] & m) == 0) panic("bfree: freeing a free block");
    bp->data[bi / 8] &= ~m;
    bwrite(bp);
    brelse(bp);
}

/* ---------- in-core inode cache ---------- */

static struct {
    struct spinlock lock;
    struct inode inode[NINODE];
} icache;

void iinit(void)
{
    initlock(&icache.lock, "icache");
    for (int i = 0; i < NINODE; i++)
        initsleeplock(&icache.inode[i].lock, "inode");
}

static struct inode *iget(uint32 dev, uint32 inum);

/* Allocate a fresh on-disk inode via the INODE BITMAP (LuitFS differs from
 * xv6 here: xv6 scans the table for type==0; we keep an explicit bitmap,
 * symmetric with data blocks - one allocation idea, applied twice). */
struct inode *ialloc(uint32 dev, uint16 type)
{
    for (uint32 i = ROOTINO; i < sb.ninodes; i += 1) {
        struct buf *bp = bread(dev, IBBLOCK(i, sb));
        uint32 bi = i % BPB;
        int m = 1 << (bi % 8);
        if ((bp->data[bi / 8] & m) == 0) {
            bp->data[bi / 8] |= m;
            bwrite(bp);
            brelse(bp);

            /* Initialize the dinode itself. */
            bp = bread(dev, IBLOCK(i, sb));
            struct dinode *dip = (struct dinode *)bp->data + i % IPB;
            memset(dip, 0, sizeof(*dip));
            dip->type = type;
            bwrite(bp);
            brelse(bp);
            return iget(dev, i);
        }
        brelse(bp);
    }
    printf("luitfs: out of inodes\n");
    return 0;
}

/* Copy a modified in-core inode to disk. Call after EVERY change to ip->
 * fields that live in the dinode. Caller holds ip->lock. */
void iupdate(struct inode *ip)
{
    struct buf *bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    struct dinode *dip = (struct dinode *)bp->data + ip->inum % IPB;
    dip->type  = ip->type;
    dip->major = ip->major;
    dip->minor = ip->minor;
    dip->nlink = ip->nlink;
    dip->size  = ip->size;
    memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    bwrite(bp);
    brelse(bp);
}

/* Find inode (dev, inum) in the cache, or claim a slot. Does NOT lock it and
 * does NOT read it from disk - ilock() does that lazily. */
static struct inode *iget(uint32 dev, uint32 inum)
{
    acquire(&icache.lock);

    struct inode *empty = 0;
    for (struct inode *ip = icache.inode; ip < icache.inode + NINODE; ip++) {
        if (ip->ref > 0 && ip->dev == dev && ip->inum == inum) {
            ip->ref++;
            release(&icache.lock);
            return ip;
        }
        if (empty == 0 && ip->ref == 0)
            empty = ip;
    }
    if (empty == 0) panic("iget: inode cache full - raise NINODE");

    struct inode *ip = empty;
    ip->dev = dev; ip->inum = inum; ip->ref = 1; ip->valid = 0;
    release(&icache.lock);
    return ip;
}

struct inode *idup(struct inode *ip)
{
    acquire(&icache.lock);
    ip->ref++;
    release(&icache.lock);
    return ip;
}

void ilock(struct inode *ip)
{
    if (ip == 0 || ip->ref < 1) panic("ilock");
    acquiresleep(&ip->lock);
    if (!ip->valid) {
        struct buf *bp = bread(ip->dev, IBLOCK(ip->inum, sb));
        struct dinode *dip = (struct dinode *)bp->data + ip->inum % IPB;
        ip->type  = dip->type;
        ip->major = dip->major;
        ip->minor = dip->minor;
        ip->nlink = dip->nlink;
        ip->size  = dip->size;
        memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
        brelse(bp);
        ip->valid = 1;
        if (ip->type == 0) panic("ilock: inode has no type (bitmap out of sync)");
    }
}

void iunlock(struct inode *ip)
{
    if (ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1) panic("iunlock");
    releasesleep(&ip->lock);
}

/* Drop a reference. If that was the LAST reference and the last LINK, the
 * inode is dead: free its data and its bitmap bit. This is where "unlink an
 * open file" is resolved - the name dies immediately, the bytes die here. */
void iput(struct inode *ip)
{
    acquire(&icache.lock);

    if (ip->ref == 1 && ip->valid && ip->nlink == 0) {
        /* No other holder can appear: iget would need ref > 0. Safe to lock. */
        acquiresleep(&ip->lock);
        release(&icache.lock);

        itrunc(ip);
        ip->type = 0;
        iupdate(ip);
        /* release the inode-bitmap bit */
        struct buf *bp = bread(ip->dev, IBBLOCK(ip->inum, sb));
        uint32 bi = ip->inum % BPB;
        if ((bp->data[bi / 8] & (1 << (bi % 8))) == 0)
            panic("iput: inode bitmap already clear");
        bp->data[bi / 8] &= ~(1 << (bi % 8));
        bwrite(bp);
        brelse(bp);
        ip->valid = 0;

        releasesleep(&ip->lock);
        acquire(&icache.lock);
    }
    ip->ref--;
    release(&icache.lock);
}

void iunlockput(struct inode *ip) { iunlock(ip); iput(ip); }

/* ---------- block mapping ---------- */

/* Return the disk block holding byte-offset block `bn` of ip, allocating it
 * (and the indirect block) on demand. 0 = out of space. Caller holds ip->lock. */
static uint32 bmap(struct inode *ip, uint32 bn)
{
    if (bn < NDIRECT) {
        uint32 addr = ip->addrs[bn];
        if (addr == 0) {
            addr = balloc(ip->dev);
            if (addr == 0) return 0;
            ip->addrs[bn] = addr;
        }
        return addr;
    }
    bn -= NDIRECT;
    if (bn < NINDIRECT) {
        /* Lab 9 extends this function with a DOUBLE-indirect level. */
        uint32 addr = ip->addrs[NDIRECT];
        if (addr == 0) {
            addr = balloc(ip->dev);
            if (addr == 0) return 0;
            ip->addrs[NDIRECT] = addr;
        }
        struct buf *bp = bread(ip->dev, addr);
        uint32 *a = (uint32 *)bp->data;
        if ((addr = a[bn]) == 0) {
            addr = balloc(ip->dev);
            if (addr) { a[bn] = addr; bwrite(bp); }
        }
        brelse(bp);
        return addr;
    }
    panic("bmap: block number beyond MAXFILE");
}

/* Free all data blocks of ip and set size 0. Caller holds ip->lock. */
void itrunc(struct inode *ip)
{
    for (int i = 0; i < NDIRECT; i++) {
        if (ip->addrs[i]) { bfree(ip->dev, ip->addrs[i]); ip->addrs[i] = 0; }
    }
    if (ip->addrs[NDIRECT]) {
        struct buf *bp = bread(ip->dev, ip->addrs[NDIRECT]);
        uint32 *a = (uint32 *)bp->data;
        for (uint32 j = 0; j < NINDIRECT; j++)
            if (a[j]) bfree(ip->dev, a[j]);
        brelse(bp);
        bfree(ip->dev, ip->addrs[NDIRECT]);
        ip->addrs[NDIRECT] = 0;
    }
    ip->size = 0;
    iupdate(ip);
}

void stati(struct inode *ip, struct stat *st)
{
    st->dev   = ip->dev;
    st->ino   = ip->inum;
    st->type  = ip->type;
    st->nlink = ip->nlink;
    st->size  = ip->size;
}

/* ---------- byte-granularity file I/O ---------- */

/* Read n bytes at offset off into dst (user va if user_dst, else kernel).
 * Returns bytes read, or -1. Caller holds ip->lock. */
int readi(struct inode *ip, int user_dst, uint64 dst, uint32 off, uint32 n)
{
    if (off > ip->size || off + n < off) return 0;
    if (off + n > ip->size) n = ip->size - off;

    uint32 tot, m;
    for (tot = 0; tot < n; tot += m, off += m, dst += m) {
        uint32 addr = bmap(ip, off / BSIZE);
        if (addr == 0) break;
        struct buf *bp = bread(ip->dev, addr);
        m = BSIZE - off % BSIZE;
        if (m > n - tot) m = n - tot;
        if (user_dst) {
            if (copyout(myproc()->pagetable, dst,
                        (char *)bp->data + off % BSIZE, m) < 0) {
                brelse(bp);
                tot = -1;
                break;
            }
        } else {
            memmove((void *)dst, bp->data + off % BSIZE, m);
        }
        brelse(bp);
    }
    return tot;
}

/* Write n bytes at off from src. Grows the file if needed. Caller holds lock. */
int writei(struct inode *ip, int user_src, uint64 src, uint32 off, uint32 n)
{
    if (off > ip->size || off + n < off) return -1;
    if (off + n > MAXFILE * BSIZE) return -1;

    uint32 tot, m;
    for (tot = 0; tot < n; tot += m, off += m, src += m) {
        uint32 addr = bmap(ip, off / BSIZE);
        if (addr == 0) break;                     /* disk full: partial write */
        struct buf *bp = bread(ip->dev, addr);
        m = BSIZE - off % BSIZE;
        if (m > n - tot) m = n - tot;
        if (user_src) {
            if (copyin(myproc()->pagetable,
                       (char *)bp->data + off % BSIZE, src, m) < 0) {
                brelse(bp);
                break;
            }
        } else {
            memmove(bp->data + off % BSIZE, (void *)src, m);
        }
        bwrite(bp);
        brelse(bp);
    }
    if (off > ip->size) ip->size = off;
    iupdate(ip);                    /* size and any new addrs[] hit the disk */
    return tot;
}

/* ---------- directories ---------- */

int namecmp(const char *s, const char *t) { return strncmp(s, t, DIRSIZ); }

/* Look up name in directory dp. Returns unlocked inode; *poff = entry offset. */
struct inode *dirlookup(struct inode *dp, char *name, uint32 *poff)
{
    if (dp->type != T_DIR) panic("dirlookup: not a directory");

    struct dirent de;
    for (uint32 off = 0; off < dp->size; off += sizeof(de)) {
        if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
            panic("dirlookup: short directory read");
        if (de.inum == 0) continue;
        if (namecmp(name, de.name) == 0) {
            if (poff) *poff = off;
            return iget(dp->dev, de.inum);
        }
    }
    return 0;
}

/* Add (name -> inum) to directory dp. -1 if name exists or no space. */
int dirlink(struct inode *dp, char *name, uint32 inum)
{
    struct inode *ip;
    if ((ip = dirlookup(dp, name, 0)) != 0) { iput(ip); return -1; }

    struct dirent de;
    uint32 off;
    for (off = 0; off < dp->size; off += sizeof(de)) {
        if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
            panic("dirlink: short directory read");
        if (de.inum == 0) break;                  /* reuse a freed slot */
    }
    strncpy(de.name, name, DIRSIZ);
    de.inum = inum;
    if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
        return -1;
    return 0;
}

/* ---------- path lookup ---------- */

/* Peel one element off path: "a/bb/c" -> name="a", return "bb/c".
 * Returns 0 when there are no more elements. */
static char *skipelem(char *path, char *name)
{
    while (*path == '/') path++;
    if (*path == 0) return 0;
    char *s = path;
    while (*path != '/' && *path != 0) path++;
    int len = path - s;
    if (len >= DIRSIZ) {
        memmove(name, s, DIRSIZ);                 /* truncate long names */
    } else {
        memmove(name, s, len);
        name[len] = 0;
    }
    while (*path == '/') path++;
    return path;
}

/* Walk path from / (or the cwd). If parent, stop one level early and copy the
 * final element into name. The RETURNED inode is unlocked and referenced. */
static struct inode *namex(char *path, int nameiparent_, char *name)
{
    struct inode *ip;
    if (*path == '/')
        ip = iget(ROOTDEV, ROOTINO);
    else
        ip = idup(myproc()->cwd);

    while ((path = skipelem(path, name)) != 0) {
        ilock(ip);
        if (ip->type != T_DIR) { iunlockput(ip); return 0; }
        if (nameiparent_ && *path == '\0') {
            iunlock(ip);                          /* stop at the parent */
            return ip;
        }
        struct inode *next = dirlookup(ip, name, 0);
        if (next == 0) { iunlockput(ip); return 0; }
        iunlockput(ip);
        ip = next;
    }
    if (nameiparent_) { iput(ip); return 0; }
    return ip;
}

struct inode *namei(char *path)
{
    char name[DIRSIZ];
    return namex(path, 0, name);
}

struct inode *nameiparent(char *path, char *name)
{
    return namex(path, 1, name);
}
