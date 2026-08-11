/* Lab 9: LuitFS consistency checker (fsck).
 *
 * Validates on-disk invariants: every data block referenced by an inode must be
 * marked used in the data bitmap, no block may be referenced by two inodes
 * (double-allocation), and every in-use inode's link count must be > 0. Returns
 * 0 if consistent, else a nonzero violation code. This is a read-only audit; it
 * does not repair (repair is an extension). */
#include "types.h"
#include "defs.h"
#include "param.h"
#include "fs.h"
#include "buf.h"

extern struct superblock sb;

/* is data block b marked used in the data bitmap? */
static int bmap_used(int dev, uint32 b)
{
    struct buf *bp = bread(dev, DBBLOCK(b, sb));
    uint32 bi = b % BPB;
    int m = 1 << (bi % 8);
    int used = (bp->data[bi / 8] & m) != 0;
    brelse(bp);
    return used;
}

/* record which data blocks we've seen referenced, to catch double-allocation.
 * We use a scratch page as a bitmap over data blocks (ndata up to ~32k fits in
 * one 4KB page = 32768 bits). */
#define FSCK_MAXDATA (PGSIZE * 8)

int fsck(int dev)
{
    if (sb.ndata > FSCK_MAXDATA) return -99;      /* fs too big for this checker */

    uint8 *seen = (uint8 *)palloc();
    if (!seen) return -1;
    memset(seen, 0, PGSIZE);

    int violation = 0;

    /* walk every inode */
    for (uint32 inum = 1; inum < sb.ninodes && !violation; inum++) {
        struct buf *ibp = bread(dev, IBBLOCK(inum, sb));
        struct dinode *din = (struct dinode *)ibp->data + (inum % IPB);
        int type = din->type;
        int nlink = din->nlink;
        uint32 addrs[NDIRECT + 1];
        for (int k = 0; k < NDIRECT + 1; k++) addrs[k] = din->addrs[k];
        brelse(ibp);

        if (type != T_DIR && type != T_FILE && type != T_DEV)
            continue;                             /* free or uninitialized inode */

        if (nlink < 1) { violation = 2; break; }

        /* check direct blocks */
        for (int k = 0; k < NDIRECT && !violation; k++) {
            uint32 b = addrs[k];
            if (b == 0) continue;
            if (b < sb.datastart || b >= sb.datastart + sb.ndata) { violation = 3; break; }
            uint32 di = b - sb.datastart;
            if (seen[di / 8] & (1 << (di % 8))) { violation = 4; break; }   /* double-alloc */
            seen[di / 8] |= (1 << (di % 8));
            if (!bmap_used(dev, b)) { violation = 5; break; }               /* referenced but free */
        }

        /* check the indirect block and its entries */
        if (!violation && addrs[NDIRECT]) {
            uint32 ib = addrs[NDIRECT];
            if (ib < sb.datastart || ib >= sb.datastart + sb.ndata) { violation = 3; }
            else {
                uint32 di = ib - sb.datastart;
                if (seen[di / 8] & (1 << (di % 8))) violation = 4;
                else {
                    seen[di / 8] |= (1 << (di % 8));
                    if (!bmap_used(dev, ib)) violation = 5;
                    struct buf *bp = bread(dev, ib);
                    uint32 *entries = (uint32 *)bp->data;
                    for (int k = 0; k < (int)NINDIRECT && !violation; k++) {
                        uint32 b = entries[k];
                        if (b == 0) continue;
                        if (b < sb.datastart || b >= sb.datastart + sb.ndata) { violation = 3; break; }
                        uint32 d2 = b - sb.datastart;
                        if (seen[d2 / 8] & (1 << (d2 % 8))) { violation = 4; break; }
                        seen[d2 / 8] |= (1 << (d2 % 8));
                        if (!bmap_used(dev, b)) { violation = 5; break; }
                    }
                    brelse(bp);
                }
            }
        }
    }

    pfree(seen);
    return violation;
}
