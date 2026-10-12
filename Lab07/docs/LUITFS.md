# LuitFS version 1 — on-disk format

Shared, single definition: `kernel/fs.h`. `mkfs/mkfs.c` writes it on the
host; the kernel reads and writes it at run time. Static asserts in mkfs pin
the structure sizes so host/target divergence fails the *build*, not the disk.

## Layout

```
block 0        boot block (unused by Luit; reserved)
block 1        superblock
ibmapstart..   inode bitmap  (1 bit per inode)
dbmapstart..   data bitmap   (1 bit per block of the WHOLE image)
inodestart..   inode table   (16 × 64-byte dinodes per 1024-byte block)
datastart..    data blocks
```

Superblock fields: `magic` (0x4C554954, "LUIT"), `version` (1), `size`,
`ninodes`, the four region starts, `ndata`, and `nlog` — **reserved, zero in
v1**: Lab 11's write-ahead journal claims it, which is why it exists now.

## Where LuitFS deliberately differs from xv6's fs

* **Inode allocation is a bitmap**, symmetric with data blocks — one
  allocation mechanism, applied twice — instead of scanning the inode table
  for `type == 0`.
* **Directory entries are 32 bytes** with a `uint32` inum and 28-char names
  (xv6: 16 bytes, `ushort`, 14 chars).
* **Versioned, magic-checked superblock** — the kernel refuses to mount
  anything else, loudly.
* `/console` is created **by mkfs** as a `T_DEV` inode; there is no `mknod`
  syscall in the baseline ABI.

## Geometry (v1 defaults)

`BSIZE` 1024 · image 2000 blocks (~2 MB) · 200 inodes · 12 direct + 1
single-indirect (256 entries) per inode → `MAXFILE` = 268 blocks ≈ 268 KB.
Lab 9 adds a double-indirect level.

## Crash behaviour — the honest statement

LuitFS v1 is **persistent but not crash-consistent**. Completed, quiescent
writes survive power-off (graded: the persistence test in `tests/grade.py`).
A crash *mid-operation* can leave orphaned blocks or a half-updated
directory: writes go straight through `bwrite` in a careful order (allocate
before reference, zero before expose), which bounds the damage but does not
eliminate it. Making that guarantee real — journalling plus ≥200 randomized
crash-injection trials — is Lab 11, and is a Tier-3 maturity requirement.

## Locking

Lock order is **parent directory → child inode → buffer**, everywhere.
`ilock`/`iunlock` are sleeplocks (I/O sleeps); `icache.lock`/`ftable.lock`
are spinlocks held only for table walks. The buffer cache has one global
lock — a deliberate bottleneck that Lab 8 measures and removes.
