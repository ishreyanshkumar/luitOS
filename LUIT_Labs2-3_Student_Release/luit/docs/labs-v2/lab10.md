# Lab 10 — Integrated Memory-Mapped Files

*CS3106L · Dr. Satyajit Das · IIT Guwahati · ~9 h take-home*

> **mmap that integrates the term.** Basic mmap has public solutions. Ours
> requires the pieces that make mmap real and that reuse your own earlier work:
> MAP_PRIVATE COW built on **Lab 5's** refcounts, msync with dirty tracking,
> correct interaction with **Lab 9's** truncation, partial unmap, and multi-
> threaded pressure using **Lab 6's** futex mutex. It is the convergence lab.

## 1. Educational objective
Implement file-backed and anonymous mappings that integrate VM, the fault path,
COW, the filesystem, and threads — where the whole term meets.

## 2. Concepts covered
VMAs; lazy fault-in; MAP_SHARED vs MAP_PRIVATE; COW for private mappings; dirty
tracking and msync; truncation vs mappings; partial unmap; fork inheritance.

## 3. Baseline components to read
`kernel/trap.c` (fault hook — now mmap too); Lab 5 (refcounts, COW fault); Lab 9
(readi/writei, truncation, inode layer); `kernel/proc.c` (VMA table storage).

## 4. Warm-up task
Lazy read-only MAP_SHARED of a file: no pages at map time; fault in via readi;
reads through the mapping return file contents. (The xv6 core — your scaffold.)

## 5. Main implementation tasks
**A** VMA table + general mmap/munmap: record a VMA (16/proc), map lazily;
munmap supports partial unmap (split a VMA); MAP_ANONYMOUS backed by Lab 5's
zero page; file-backed.
**B** MAP_PRIVATE via COW (reuse Lab 5): private pages shared RO until written,
then copied by the same refcount machinery; file never modified; fork shares COW.
**C** MAP_SHARED write-back + msync: writes visible to other mappers and
eventually the file; track dirty pages; msync/munmap write back only dirtied.
**D** truncation interaction (reuse Lab 9): access past a truncated file's new
end faults (SIGBUS-like), no stale data.
**E** fork & exit: fork inherits mappings (shared stays shared, private→COW);
exit unmaps all and writes back shared dirty pages.
**F** memory-pressure test (reuse Lab 6): threads map/touch/unmap under small -m,
synchronized with your futex mutex; no leaks, correct data.

## 6. Requirements that differ from xv6
MAP_PRIVATE COW integrated with Lab 5, msync+dirty tracking, truncation with Lab
9, partial unmap w/ VMA splitting, multi-threaded pressure with Lab 6 — none in
the public mmap solution.

## 7. Required interfaces and system calls
`mmap(addr,len,prot,flags,fd,off)`; `munmap(addr,len)` (partial); `msync(addr,len,flags)`.

## 8. Required data structures
Per-process VMA table: `struct vma{uint64 start,len; int prot,flags; struct file
*f; uint64 off;}`; dirty tracking (PTE dirty bit or per-VMA bitmap).

## 9. Concurrency and locking requirements
VMA table guarded per-process; on a shared (threaded) AS, page installation
serialized (reuse Lab 5's single-copy discipline); msync holds the inode lock
per Lab 9 order.

## 10. Error-handling requirements
mmap of bad fd/offset/len → -1; access to a truncated-away region → process
fault, kernel survives; partial munmap leaves the remainder correct, writes back
shared+dirty; OOM during fault-in → faulting process dies, others intact.

## 11. Integration with previous labs
**Directly reuses Lab 5 (COW refcounts), Lab 6 (futex mutex), Lab 9 (readi/writei,
truncation).** The convergence lab; a broken earlier lab shows up here.

## 12. Public tests (`make grade LAB=10`)
RO MAP_SHARED returns file contents lazily; MAP_PRIVATE write doesn't modify the
file, another mapper sees the original; MAP_SHARED write + msync visible on
re-read; partial munmap of the middle splits correctly.

## 13. Hidden tests
Private COW + fork: parent and child each see own writes, file unchanged; dirty
tracking: msync writes back only modified (verified via Lab 2 trace); truncation
access faults, kernel survives; N-thread pressure under small -m, data correct,
Lab 5 pgaudit==0; partial-unmap of a dirty shared sub-range flushes it.

## 14. Performance measurement
Fault-in cost per page; msync cost vs dirty-page count; private-COW copy count
under a write workload; pressure-test throughput with the futex mutex.

## 15. Required report (≤3 pages)
VMA design + partial-unmap splitting; how MAP_PRIVATE reuses Lab 5; dirty
tracking + msync; truncation-fault with Lab 9; the threaded pressure result.

## 16. Viva questions
How does MAP_PRIVATE reuse your Lab 5 refcounts — what's shared, what's copied?
How do you track dirty pages, and what does msync skip? What happens on
truncation under a mapping? Two threads fault one mapped page — installed once how?

## 17. Expected workload
~9h: 2h VMA/mmap/munmap, 2h private-COW, 2h msync/dirty, 2h truncation+pressure,
1h report.

## 18. Starter code provided
`kernel/vma.h`; mmap fault hook marked in trap.c; `user/mmaptest.c` skeleton;
`tests/lab10/` integration harness.

## 19. Staff-only reference requirements
VMA table with splitting; private-COW via Lab 5; dirty bitmap + msync;
truncation-fault; threaded pressure baseline.

## 20. Common incorrect approaches
Eager fault-in of the whole file; MAP_PRIVATE writing the file; msync flushing
everything; no truncation handling; duplicating COW instead of reusing Lab 5
(works but flagged; viva penalizes).

## 21. Suggested rubric (100)
VMA+mmap/munmap 18 · private COW (reuse L5) 18 · msync+dirty 15 · truncation 12 ·
pressure (reuse L6) 12 · measurement 10 · viva 15.

## 22. LLM-use declaration
Appendix. Basic mmap is documented; the integration with Labs 5/6/9 is yours and
the viva targets those seams.

## 23. Anti-copying check
Public mmap = basic file-backed faulting. The MAP_PRIVATE-COW-reusing-Lab-5,
dirty msync, truncation, and threaded-pressure requirements need your own earlier
code; the Lab-5-reuse and single-install viva expose copied cores.
