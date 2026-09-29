CS3106L Lab 6 - Blocking Mailboxes in LUIT
==========================================

IMPORTANT: THIS ZIP IS A LAB 6 OVERLAY, NOT A COMPLETE LUIT TREE.

It intentionally does NOT contain LUIT's top-level Makefile. Start from the
completed Lab 4 LUIT tree that already builds with `make`; the installer patches
that existing Makefile. Do not run the preflight against this package directory.

The course LUIT tree also does NOT use kernel/proc.h or kernel/spinlock.h for
this lab. Do not create either file and do not copy them from xv6. The supplied
mailbox.c includes kernel/defs.h, while the existing spinlock implementation
remains in kernel/spinlock.c.

Start with the PDF handout:
  Lab06_Blocking_Mailboxes_LUIT.pdf

Use a scratch copy/branch of the completed LUIT tree. A Lab 4-complete tree is sufficient; the non-graded Lab 5 practicum additions are optional.

1. Check compatibility from this package directory:
   python3 tools/lab06_preflight.py /path/to/LUIT_TREE

2. Install the Lab 6 release overlay:
   python3 tools/install_lab06.py /path/to/LUIT_TREE

3. In the LUIT root:
   python3 tools/lab06_check.py
   make clean
   make

4. Implement only TODO regions M1--M5 and optional helper code between
   the LAB6-HELPERS markers in:
   kernel/mailbox.c

5. During development:
   python3 tests/grade_lab06.py --quick

6. Final local verification:
   python3 tests/grade_lab06.py

7. Create the submission archive (replace with your nine-digit roll number):
   python3 tools/package_lab06.py 230101037

   This creates:
   230101037_Lab06.zip

The archive contains only the implementation source required for grading:
  230101037_Lab06/kernel/mailbox.c

The public tests are not an exhaustive specification. The PDF defines the
required blocking, FIFO, close, multiple-waiter, wakeup, SMP, and integrity behaviour.
