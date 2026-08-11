# LLM Use Policy — CS3106L (BrahmaputraOS / Luit)
*Dr. Satyajit Das · Department of Computer Science and Engineering · IIT Guwahati*

## Principle

You will use AI assistants professionally for the rest of your career; this
course teaches you to use them the way a kernel engineer does — as a rubber
duck, a documentation index, and a reviewer — while guaranteeing the *system
understanding* ends up in your head, because the viva examines your head, not
your repository.

## The three modes

* **GREEN (always permitted):** explaining concepts, explaining *provided*
  baseline code, RISC-V/virtio/FDT spec questions, debugging *your own error
  messages by pasting them*, GDB usage, English polish on reports.
* **AMBER (permitted with logging):** design discussions for the current lab
  ("what are the trade-offs of bucket-hash vs LRU-list here"), reviewing a diff
  you already wrote, test-case brainstorming.
* **RED (never permitted):** generating solution code for the current lab's
  graded functions; pasting another student's or a solution repo's code for
  "explanation"; using an agentic tool that edits your working tree.

## Per-lab lines

The GREEN/AMBER/RED boundary shifts with the lab's learning target — the
graded skill is what the LLM must not do for you:

| Lab | RED specifically includes | AMBER note |
|-----|---------------------------|------------|
| 1 util | generating any of the 5 utilities | pipe-semantics questions are GREEN — that's reading, not writing |
| 2 syscall | trace/sysinfo handler code | asking "why copyout" is GREEN and encouraged |
| 3 pgtbl | walk/vmprint/pgaccess code | the no-trampoline design discussion is GREEN — it's a viva topic |
| 4 traps | backtrace/sigalarm logic | RISC-V calling-convention questions GREEN |
| 5 cow | the fault-handler and uvmcopy logic | drawing the refcount state machine with an LLM is AMBER |
| 6 thread | uthread_switch.S; the ph/barrier fixes | register-convention questions GREEN |
| 7 net | driver code | ring-protocol questions against OUR virtio_blk.c are GREEN — reading the worked example is the assignment |
| 8 lock | the locking schemes | deadlock-ordering *review* of code you already wrote is AMBER |
| 9 fs | bmap/symlink code | on-disk format design chat is AMBER with log |
| 10 mmap | VMA/fault/write-back code | semantics-of-MAP_PRIVATE discussion GREEN |
| 11 crash | the log layer | failure-model discussion AMBER; the hidden seeds defeat generated pattern-code anyway |
| 12 silicon | nothing extra | board docs aren't in any model's training data — you'll see |

## The log

Every AMBER session is logged in `LLM_LOG.md` in your repo, one row per
session: **date · tool+model · what you asked (verbatim or summary) · what you
took from it · where it landed (file/decision) · what you verified yourself.**
The log is submitted with each lab and sampled in vivas: "your log says the
LLM suggested bucket ordering — defend that ordering now, without it."

An empty log is fine. A false log is an academic-integrity violation, treated
exactly like plagiarism.

## Enforcement reality

We assume detection is unreliable and design assessment so copying doesn't
pay: 30% of marks sit in vivas keyed to *your* diffs, hidden tests punish
pattern-matched solutions that miss Luit-specific structure (our fs is not
xv6's; our page tables are not xv6's), and Lab 12 involves hardware nobody's
model has seen.
