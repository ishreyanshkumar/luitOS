/* mkfs - build a LuitFS v1 image on the HOST and populate it with the user
 * programs. Runs on your laptop (or CI), not inside Luit: the kernel only
 * ever sees a finished image.
 *
 * The on-disk format is shared with the kernel via kernel/fs.h. Static
 * asserts pin the structure sizes: if host padding ever diverged from the
 * target, the build fails instead of producing a corrupt disk. Both ends are
 * little-endian (x86-64 host, RV64 target), and every field is an explicit-
 * width integer, so plain struct writes are well-defined here.
 *
 * Layout written:  [ boot | super | inode bitmap | data bitmap | inodes | data ]
 * The DATA BITMAP covers every block in the image; this tool pre-marks the
 * metadata region as allocated so the kernel's balloc can never hand it out.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <assert.h>
#include <stdint.h>

typedef uint8_t  uint8;
typedef uint16_t uint16;
typedef uint32_t uint32;
typedef uint64_t uint64;
#define LUIT_TYPES_H            /* use the host stdint versions above */
#include "../kernel/fs.h"

_Static_assert(sizeof(struct dinode) == 64,  "dinode must be exactly 64 bytes");
_Static_assert(sizeof(struct dirent) == 32,  "dirent must be exactly 32 bytes");
_Static_assert(BSIZE % sizeof(struct dinode) == 0, "inodes must pack a block");

#define FSSIZE  2000            /* blocks: ~2 MB image */
#define NINODES 200

static int fsfd;
static struct superblock sb;
static uint32 freeinode = ROOTINO;
static uint32 freeblock;        /* first never-yet-allocated data block */

static void wsect(uint32 sec, const void *buf)
{
    if (lseek(fsfd, sec * BSIZE, SEEK_SET) != (off_t)(sec * BSIZE)) { perror("lseek"); exit(1); }
    if (write(fsfd, buf, BSIZE) != BSIZE) { perror("write"); exit(1); }
}
static void rsect(uint32 sec, void *buf)
{
    if (lseek(fsfd, sec * BSIZE, SEEK_SET) != (off_t)(sec * BSIZE)) { perror("lseek"); exit(1); }
    if (read(fsfd, buf, BSIZE) != BSIZE) { perror("read"); exit(1); }
}

static void winode(uint32 inum, struct dinode *ip)
{
    char buf[BSIZE];
    uint32 bn = IBLOCK(inum, sb);
    rsect(bn, buf);
    ((struct dinode *)buf)[inum % IPB] = *ip;
    wsect(bn, buf);
}
static void rinode(uint32 inum, struct dinode *ip)
{
    char buf[BSIZE];
    rsect(IBLOCK(inum, sb), buf);
    *ip = ((struct dinode *)buf)[inum % IPB];
}

static void bitset(uint32 bmapstart, uint32 idx)
{
    char buf[BSIZE];
    rsect(bmapstart + idx / BPB, buf);
    buf[(idx % BPB) / 8] |= 1 << (idx % 8);
    wsect(bmapstart + idx / BPB, buf);
}

static uint32 ialloc(uint16 type, uint16 major)
{
    uint32 inum = freeinode++;
    struct dinode din;
    memset(&din, 0, sizeof(din));
    din.type  = type;
    din.major = major;
    din.nlink = 1;
    winode(inum, &din);
    bitset(sb.ibmapstart, inum);
    return inum;
}

static uint32 balloc_img(void)
{
    uint32 b = freeblock++;
    if (b >= FSSIZE) { fprintf(stderr, "mkfs: image full\n"); exit(1); }
    bitset(sb.dbmapstart, b);
    return b;
}

/* Append n bytes to inode inum (direct + single-indirect, like the kernel). */
static void iappend(uint32 inum, const void *xp, uint32 n)
{
    const char *p = xp;
    struct dinode din;
    rinode(inum, &din);
    uint32 off = din.size;

    while (n > 0) {
        uint32 fbn = off / BSIZE;
        assert(fbn < MAXFILE);
        uint32 bn;
        if (fbn < NDIRECT) {
            if (din.addrs[fbn] == 0) din.addrs[fbn] = balloc_img();
            bn = din.addrs[fbn];
        } else {
            if (din.addrs[NDIRECT] == 0) din.addrs[NDIRECT] = balloc_img();
            uint32 ind[NINDIRECT];
            rsect(din.addrs[NDIRECT], ind);
            if (ind[fbn - NDIRECT] == 0) {
                ind[fbn - NDIRECT] = balloc_img();
                wsect(din.addrs[NDIRECT], ind);
            }
            bn = ind[fbn - NDIRECT];
        }
        uint32 n1 = (fbn + 1) * BSIZE - off;
        if (n1 > n) n1 = n;
        char buf[BSIZE];
        rsect(bn, buf);
        memcpy(buf + off - fbn * BSIZE, p, n1);
        wsect(bn, buf);
        off += n1; p += n1; n -= n1;
    }
    din.size = off;
    winode(inum, &din);
}

static void dirent_add(uint32 dir, const char *name, uint32 inum)
{
    struct dirent de;
    memset(&de, 0, sizeof(de));
    de.inum = inum;
    strncpy(de.name, name, DIRSIZ);
    iappend(dir, &de, sizeof(de));
}

int main(int argc, char *argv[])
{
    if (argc < 2) {
        fprintf(stderr, "usage: mkfs fs.img [programs...]\n");
        exit(1);
    }

    /* Geometry. Bitmap blocks are sized to cover the whole image. */
    uint32 nibmap = (NINODES + BPB - 1) / BPB;
    uint32 ndbmap = (FSSIZE + BPB - 1) / BPB;
    uint32 ninodeblocks = (NINODES + IPB - 1) / IPB;

    memset(&sb, 0, sizeof(sb));
    sb.magic      = LUITFS_MAGIC;
    sb.version    = LUITFS_VERSION;
    sb.size       = FSSIZE;
    sb.ninodes    = NINODES;
    sb.ibmapstart = 2;
    sb.dbmapstart = sb.ibmapstart + nibmap;
    sb.inodestart = sb.dbmapstart + ndbmap;
    sb.datastart  = sb.inodestart + ninodeblocks;
    sb.ndata      = FSSIZE - sb.datastart;
    sb.nlog       = 0;                       /* Lab 11 claims a journal here */
    freeblock     = sb.datastart;

    fsfd = open(argv[1], O_RDWR | O_CREAT | O_TRUNC, 0666);
    if (fsfd < 0) { perror(argv[1]); exit(1); }

    char zero[BSIZE];
    memset(zero, 0, sizeof(zero));
    for (uint32 i = 0; i < FSSIZE; i++) wsect(i, zero);

    char sbbuf[BSIZE];
    memset(sbbuf, 0, sizeof(sbbuf));
    memcpy(sbbuf, &sb, sizeof(sb));
    wsect(1, sbbuf);

    /* The metadata region is not allocatable - mark every block of it used.
     * Skipping this is the classic mkfs bug: the FIRST balloc in the kernel
     * hands out the superblock, and the disk eats itself. */
    for (uint32 b = 0; b < sb.datastart; b++) bitset(sb.dbmapstart, b);
    bitset(sb.ibmapstart, 0);                /* inode 0 is never valid */

    /* Root directory. */
    uint32 root = ialloc(T_DIR, 0);
    assert(root == ROOTINO);
    dirent_add(root, ".",  root);
    dirent_add(root, "..", root);

    /* /console - the device file init opens as fds 0/1/2. Major 1 = CONSOLE.
     * (LuitFS puts this in mkfs rather than adding a mknod syscall: the
     * baseline ABI stays smaller, and the device exists from first boot.) */
    dirent_add(root, "console", ialloc(T_DEV, 1));

    /* User programs: strip the user/ prefix and any leading _ convention. */
    for (int i = 2; i < argc; i++) {
        const char *name = strrchr(argv[i], '/');
        name = name ? name + 1 : argv[i];

        int fd = open(argv[i], O_RDONLY);
        if (fd < 0) { perror(argv[i]); exit(1); }

        uint32 inum = ialloc(T_FILE, 0);
        dirent_add(root, name, inum);

        char buf[BSIZE];
        int n;
        while ((n = read(fd, buf, sizeof(buf))) > 0)
            iappend(inum, buf, n);
        close(fd);
    }

    /* Root dir sizing: nlink for "." handled by convention (nlink=1 + "."
     * self-reference is fine for v1 since we never unlink /). */
    struct dinode din;
    rinode(root, &din);
    din.size = ((din.size + BSIZE - 1) / BSIZE) * BSIZE;
    winode(root, &din);

    printf("mkfs: %s: %u blocks (%u metadata, %u data), %u inodes, %d programs\n",
           argv[1], FSSIZE, sb.datastart, sb.ndata, NINODES, argc - 2);
    close(fsfd);
    return 0;
}
