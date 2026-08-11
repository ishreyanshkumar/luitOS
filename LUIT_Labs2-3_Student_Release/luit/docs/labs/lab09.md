# Lab 9: fs — File System

*Weight: 5% of course grade · You will touch: kernel/fs.c, kernel/sysfile.c, kernel/fs.h*

**Goal.** Extend LuitFS: large files and symbolic links.

**Tasks.**
1. *bigfile:* re-purpose one direct slot as a double-indirect block; MAXFILE grows from 268 blocks to ~65,800. `bmap` and `itrunc` both change — the marked comment in `bmap` is your entry point. mkfs must agree (both share fs.h — change it once).
2. *symlink:* `symlink(target, path)` creates a T_SYMLINK inode whose data is the target path; `open` follows up to 10 deep (then errors — be ready to say why 10), `O_NOFOLLOW` doesn't.
3. This changes the on-disk format: bump LUITFS_VERSION to 2, refuse v1 images with a clear message, and update docs/LUITFS.md. Format discipline is graded.

**Viva seeds.** Why must the version bump exist, and who pays for it? Why is the symlink depth limit not just a stack-safety hack?

---

## Ground rules (all labs)

* Branch from `release/lab09`; `make grade LAB=9` must pass before submission; CI runs the same plus hidden tests.
* Your kernel must still pass **all baseline tests** — regressions cost marks even when the new feature works.
* The LLM policy for this lab is in `docs/LLM_POLICY.md`. Log every AMBER session as specified there.
