LUIT Non-Graded Page-Fault Lab Supplement v1.1
=========================================

Use this supplement with a scratch copy or scratch branch of your COMPLETED
Lab 3 Luit tree. It does not replace the Lab 3 directory.

Files in this supplement:

  user/pfdemo.c
  docs/CS3106L_NonGraded_PageFault_Practicum.md
  docs/pagefault.gdb
  docs/temporary_guard_repair.patch
  docs/TA_PageFault_Practicum_Notes.md

Apply the student files as follows:

1. Copy user/pfdemo.c to:
       <luit>/user/pfdemo.c

2. Copy docs/pagefault.gdb to:
       <luit>/docs/pagefault.gdb

3. Copy docs/temporary_guard_repair.patch to:
       <luit>/docs/temporary_guard_repair.patch

4. Append user/pfdemo to the UPROGS variable in the Makefile.

5. Rebuild:
       make clean
       make

6. Follow:
       docs/CS3106L_NonGraded_PageFault_Practicum.md

Important:

- Use a completed Lab 3 tree so the USYSINFO page is already implemented.
- Use a scratch copy or branch. One controlled experiment temporarily changes
  kernel/trap.c so the stack guard page can be repaired and retried.
- Revert that temporary change immediately after the controlled experiment.
- The COW and mmap sections teach the page-fault mechanisms. They do not
  include complete COW or mmap implementations.
- There is no submission, grader, or report for this lab.
