# Lab 9 — LuitFS Evolution: Rename, Checksums, fsck & Versioning

*CS3106L · Dr. Satyajit Das · IIT Guwahati · double-lab · ~10 h take-home*

> **Not "add double-indirect + symlink."** Those are the copyable xv6 fs tasks.
> Ours evolves LuitFS as a *format*: an atomic `rename`, block checksums, an
> `fsck` that validates and repairs, and — the part no xv6 lab has — an on-disk
> **version bump** with a **migration** that upgrades v1→v2 and refuses
> incompatible images.

## 1. Educational objective
Evolve a persistent on-disk format safely: add features, detect corruption,
validate/repair, version, and migrate existing images.

## 2. Concepts covered
On-disk layout/invariants; atomicity of a metadata op without a full journal
(that's Lab 11); checksums; consistency checking/repair; format versioning and
migration; mount-time validation.

## 3. Baseline components to read
`kernel/fs.c`, `kernel/fs.h` (layout, inodes, dirlink, bitmaps, superblock w/
reserved version/nlog); `mkfs/mkfs.c`; `docs/LUITFS.md`.

## 4. Warm-up task
Add `symlink` (T_SYMLINK inode; open follows to a depth limit). Touches the
format lightly and motivates the version bump.

## 5. Main implementation tasks
**A** atomic `rename(old,new)`: `new` always names old or new, never nothing/half
-linked, safe to concurrent readers (ordering; full crash-atomicity is Lab 11).
**B** block/inode checksums stored in-format; verify on read, update on write;
corruption detected not silently returned.
**C** on-disk v2 + migration: v2 mounts normally; v1 migrated in place (or via
`fsupgrade`); unknown/newer version refused with a clear message.
**D** fsck: validate bitmaps, link counts, orphans, checksums, connectivity;
repair the safe ones, flag the unsafe.
**E** measure/validate: corrupt an image (checksums catch it, fsck reports);
migrate a v1 image (mounts v2, data intact).

## 6. Requirements that differ from xv6
Atomic rename, checksums, fsck with repair, and especially format versioning +
migration + refusal — none in the xv6 fs/big-files labs.

## 7. Required interfaces and system calls
`rename(old,new)`; `fsck` tool (+ any fs_validate syscall); `fsupgrade` or
automatic mount-time migration.

## 8. Required data structures
v2 superblock (version, checksum-region descriptor, feature flags); per-block/
inode checksum storage; fsck's in-memory bitmaps.

## 9. Concurrency and locking requirements
rename follows LuitFS lock order (parent→child inode→buffer); locking two
directories → order by inode number; concurrent namei never sees a missing entry;
checksum update + block write consistent under the buffer-cache lock.

## 10. Error-handling requirements
rename across incompatible types / onto non-empty dir → error, no partial state;
checksum mismatch on read → error (logged), not silent bad data; unknown version
→ mount refused; migration failure → original image intact.

## 11. Integration with previous labs
The versioning mechanism is what **Lab 11's journal rides on** (reuses mount-time
validate/upgrade). fsck is reused to validate images after Lab 11's crash campaigns.

## 12. Public tests (`make grade LAB=9`)
rename a b → b names a's file, a gone, data intact; a byte-flip caught by
checksum on next read; fsck on a clean image reports nothing; a v1 image mounts
(migrated) and files readable.

## 13. Hidden tests
Concurrent rename/read never flickers ENOENT-then-exists; fsck repairs a wrong
link count then validates clean; orphan inode found+freed; version-99 image
refused; a populated v1 image migrates byte-identical.

## 14. Performance measurement
Checksum overhead read/write (with/without); migration time for N files; fsck
time vs image size.

## 15. Required report (≤3 pages)
v2 layout + why each field; rename ordering + concurrent-reader argument;
checksum scheme; fsck repair/flag policy; migration integrity guarantee.

## 16. Viva questions
Show the rename ordering keeping new always valid to a concurrent reader. Why
bump the version, and what must mount do per case? What does fsck repair vs
refuse? How does migration avoid corrupting a v1 image if it fails midway?

## 17. Expected workload
~10h: 2h rename, 2h checksums, 3h fsck, 2h versioning+migration, 1h report.

## 18. Starter code provided
mkfs with a --version flag; fs.h v2 fields marked TODO; fsck skeleton;
`tests/lab09/` corruption + migration harness.

## 19. Staff-only reference requirements
v2 format; ordered rename; checksum verify/update; fsck with repair; mount-time
migrate/refuse; corruption + migration baselines.

## 20. Common incorrect approaches
rename as unlink-then-link (window where new doesn't exist); checksums not
verified on read; in-place migration without rollback; mounting an unknown version.

## 21. Suggested rubric (100)
symlink 8 · atomic rename 18 · checksums 15 · fsck 20 · versioning+migration 20 ·
measurement 9 · viva 10.

## 22. LLM-use declaration
Appendix. fsck logic/checksums are describable; your versioning/migration design
and the rename-ordering argument are the graded originality.

## 23. Anti-copying check
xv6 fs labs never touch versioning, migration, checksums, or fsck-with-repair.
The migration-integrity and version-refusal hidden tests + the rename-ordering
viva defeat copied fragments.
