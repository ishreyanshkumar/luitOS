/* LuitFS version 1 - the on-disk format. See docs/LUITFS.md for the full
 * specification and the design rationale.
 *
 * Disk layout, in 1 KiB blocks:
 *
 *   [ boot | superblock | inode bitmap | data bitmap | inode table | data ]
 *     blk0      blk1       ibmapstart     dbmapstart    inodestart   datastart
 *
 * Unlike xv6 (which scans the inode table for type==0), LuitFS allocates
 * inodes through an explicit INODE BITMAP, symmetrical with the data bitmap.
 *
 * EVERY field is an explicit-width little-endian integer. The layout must not
 * depend on host struct padding: mkfs and the kernel share this header and
 * both are little-endian RV64/x86-64, and the static asserts below pin the
 * sizes so a padding change fails the build instead of corrupting disks.
 */
#ifndef LUIT_FS_H
#define LUIT_FS_H

#define LUITFS_MAGIC   0x4C554954u   /* "LUIT" */
#define LUITFS_VERSION 1
#define BSIZE          1024          /* block size in bytes */

struct superblock {
    uint32 magic;        /* LUITFS_MAGIC                        */
    uint32 version;      /* LUITFS_VERSION                      */
    uint32 size;         /* total number of blocks in the image */
    uint32 ninodes;      /* number of inodes                    */
    uint32 ndata;        /* number of data blocks               */
    uint32 ibmapstart;   /* first block of the inode bitmap     */
    uint32 dbmapstart;   /* first block of the data bitmap      */
    uint32 inodestart;   /* first block of the inode table      */
    uint32 datastart;    /* first data block                    */
    uint32 nlog;         /* journal blocks - 0 in v1, Lab 11 territory */
};

#define ROOTINO  1                   /* root directory inode number */

#define NDIRECT   12
#define NINDIRECT (BSIZE / sizeof(uint32))
#define MAXFILE   (NDIRECT + NINDIRECT)      /* blocks; Lab 9 raises this */

/* On-disk inode: exactly 64 bytes, 16 per block. */
struct dinode {
    uint16 type;                 /* T_DIR, T_FILE, T_DEV, or 0 = free */
    uint16 major;                /* T_DEV only                        */
    uint16 minor;                /* T_DEV only                        */
    uint16 nlink;                /* directory entries pointing here   */
    uint32 size;                 /* file size in bytes                */
    uint32 addrs[NDIRECT + 1];   /* direct blocks + single indirect   */
};

#define T_DIR  1
#define T_FILE 2
#define T_DEV  3

#define IPB (BSIZE / sizeof(struct dinode))          /* inodes per block  */
#define IBLOCK(i, sb)  ((i) / IPB + (sb).inodestart) /* block holding inode i */
#define BPB (BSIZE * 8)                              /* bitmap bits per block */
#define IBBLOCK(i, sb) ((i) / BPB + (sb).ibmapstart) /* inode-bitmap block */
#define DBBLOCK(b, sb) ((b) / BPB + (sb).dbmapstart) /* data-bitmap block  */

/* Directory entry: exactly 32 bytes. */
#define DIRSIZ 28
struct dirent {
    uint32 inum;                 /* 0 = free slot */
    char   name[DIRSIZ];
};

#endif
