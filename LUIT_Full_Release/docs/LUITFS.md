# LuitFS version 1 — on-disk format

The shared format definition is `kernel/fs.h`. `mkfs/mkfs.c` writes the image
on the host and the kernel reads and updates it at run time. Static assertions
in `mkfs` detect host/target structure-size mismatches.

## Layout

```text
block 0        reserved boot block
block 1        superblock
ibmapstart..   inode bitmap
dbmapstart..   data bitmap
inodestart..   inode table
datastart..    data blocks
```

The superblock contains the magic value `0x4C554954`, format version, image
size, inode count, region offsets, data-block count, and one reserved 32-bit field.

## Distinguishing properties

- Inodes and data blocks use bitmap allocation.
- Directory entries are 32 bytes: a 32-bit inode number and a 28-byte name.
- The superblock is versioned and magic-checked at mount time.
- `/console` is created by `mkfs` as a device inode.

## Default geometry

`BSIZE` is 1024 bytes. The default image has 2000 blocks and 200 inodes. Each
inode has 12 direct pointers and one single-indirect pointer, allowing 268 data
blocks per file.

## Persistence behaviour

LuitFS v1 is persistent but not crash-consistent. A completed, quiescent write
survives a normal shutdown, but a power loss during a metadata operation can
leave orphaned blocks or a partially updated directory. Allocation and exposure
are ordered to limit damage, but there is no transactional recovery protocol.

## Locking

The lock order is parent-directory inode, child inode, then buffer. Inode locks
are sleeplocks because storage operations may sleep; table locks are spinlocks
held only for short critical sections. The buffer cache uses a single global
metadata lock and per-buffer sleeplocks.
