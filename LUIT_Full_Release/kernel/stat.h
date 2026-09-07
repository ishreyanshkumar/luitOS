#ifndef LUIT_STAT_H
#define LUIT_STAT_H
struct stat {
    int    dev;      /* disk device        */
    uint32 ino;      /* inode number       */
    uint16 type;     /* T_DIR/T_FILE/T_DEV */
    uint16 nlink;    /* number of links    */
    uint64 size;     /* size in bytes      */
};
#endif
