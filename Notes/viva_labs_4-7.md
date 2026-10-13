# Comprehensive Viva Preparation Guide: Labs 4, 5, 6, and 7
**Course:** CS3106L Operating Systems Laboratory, IIT Guwahati  
**Kernel:** BrahmaputraOS / LUIT (RISC-V)

---

# EXECUTIVE SUMMARY & LAB ROADMAP

| Lab | Problem Tackled | Key Kernel Mechanism | What Proves It Works |
| :--- | :--- | :--- | :--- |
| **Lab 4** | Eager memory waste & page fault handling | Lazy heap reservation (`p->sz`), page-fault trap repair, lazy kernel copy (`user_resolve_pa`) | `lazytest` (reserves memory without RAM; fault materializes zero-filled pages on demand) |
| **Lab 5** | Race conditions & unbounded waiting | Atomic `amoswap`, `push_off`/`pop_off`, `sleep(chan, &lock)` | `race_demo` (lost update $\rightarrow$ 0 lost); `pipe_stress` (8192 bytes through 512B pipe without drop) |
| **Lab 6** | Multicore Inter-Process Communication | Bounded MPMC circular queue with `rchan`/`wchan` & drain-on-close | `mbox_stress` (4 producers, 4 consumers on 4 cores with zero dropped/duplicated messages) |
| **Lab 7** | Deterministic CPU resource sharing | Minimum pass stride selection ($S = \text{BIG}/T$) + global `stride_floor` clamping | `stride_share` (100:50:250 tickets achieve precise proportional CPU dispatches) |

---

# TABLE OF CONTENTS
1. [LAB 4: Fault-Driven Heap Allocation (Lazy Page Allocation)](#lab-4-fault-driven-heap-allocation-lazy-page-allocation)
   - [1.1 The Core Idea: Eager vs. Lazy Allocation](#11-the-core-idea-eager-vs-lazy-allocation)
   - [1.2 Address Space Layout & Legal vs. Illegal Accesses](#12-address-space-layout--legal-vs-illegal-accesses)
   - [1.3 The 4 Graded Tasks (K1, K2, K3, K4)](#13-the-4-graded-tasks-k1-k2-k3-k4)
   - [1.4 High-Yield Viva Questions for Lab 4](#14-high-yield-viva-questions-for-lab-4)
2. [LAB 5: Concurrency, Locks, and Sleep/Wakeup](#lab-5-concurrency-locks-and-sleepwakeup)
   - [2.1 Race Conditions & Lost Updates](#21-race-conditions--lost-updates)
   - [2.2 Hardware Atomicity & Spinlocks](#22-hardware-atomicity--spinlocks)
   - [2.3 Interrupt Discipline & Same-Hart Deadlock](#23-interrupt-discipline--same-hart-deadlock)
   - [2.4 Sleep / Wakeup & The Lost-Wakeup Bug](#24-sleep--wakeup--the-lost-wakeup-bug)
   - [2.5 Bounded Pipe Concurrency Case Study](#25-bounded-pipe-concurrency-case-study)
3. [LAB 6: Bounded Blocking Mailboxes](#lab-6-bounded-blocking-mailboxes)
   - [3.1 Subsystem Design & State Representation](#31-subsystem-design--state-representation)
   - [3.2 Sleep Channels (`rchan` vs `wchan`)](#32-sleep-channels-rchan-vs-wchan)
   - [3.3 Operation Walkthroughs (Send, Recv, Close)](#33-operation-walkthroughs-send-recv-close)
   - [3.4 Critical Edge Cases & Common Traps](#34-critical-edge-cases--common-traps)
4. [LAB 7: Deterministic Proportional-Share (Stride) Scheduling](#lab-7-deterministic-proportional-share-stride-scheduling)
   - [4.1 Stride Scheduling Fundamentals & Mathematical Proof](#41-stride-scheduling-fundamentals--mathematical-proof)
   - [4.2 The 3 Classic Pitfalls & How LUIT Solves Them](#42-the-3-classic-pitfalls--how-luit-solves-them)
   - [4.3 SMP Selection Algorithm & Locking Contract](#43-smp-selection-algorithm--locking-contract)
   - [4.4 Summary of Lab 7 Implementation Regions (S1–S6)](#44-summary-of-lab-7-implementation-regions-s1s6)

---

# LAB 4: Fault-Driven Heap Allocation (Lazy Page Allocation)

## 1.1 The Core Idea: Eager vs. Lazy Allocation
- **Eager Allocation (Old behavior):** When a user calls `sbrk(n)`, the kernel immediately allocates $n$ bytes worth of physical RAM via `palloc()`, zeroes them, and installs leaf Page Table Entries (PTEs).
  - *Problem:* Programs often allocate huge buffers (e.g. 100 MB sparse arrays) but only touch a few pages. Eagerly allocating everything wastes RAM, burns CPU cycles zeroing untouched memory, and risks early Out-Of-Memory (OOM) failures.
- **Lazy Allocation (Lab 4 behavior):** When `sbrk(n)` is called with $n > 0$, the kernel **only increases `p->sz`**.
  - No physical pages are allocated (`palloc` is NOT called).
  - No PTEs are created.
  - The address space is merely **reserved**. Physical memory is supplied **on-demand** when the process actually touches a page.

---

## 1.2 Address Space Layout & Legal vs. Illegal Accesses

```text
Higher Addresses (User Top)
  | 
  |  USYSINFO_VA (Lab 3 shared info page - Read Only)
  | 
  +--------------------------------+  <-- p->sz (Current heap boundary / "break")
  |                                |
  |       LAZY HEAP REGION         |  <-- [p->heapbase, p->sz)
  |   (Legal to allocate on fault) |
  |                                |
  +--------------------------------+  <-- p->heapbase
  |          User Stack            |
  +--------------------------------+
  |       Stack Guard Page         |  <-- UNMAPPED (PTE_V == 0)! MUST CRASH IF TOUCHED!
  +--------------------------------+
  |      Program Code & Data       |
Lower Addresses (0x0)
```

### What is `p->sz`?
- `p->sz` is a **virtual memory address (byte-granular)** representing the current break (top ceiling) of the process.
- **It is NOT a count of mapped pages!**
  $$\mathbf{p\text{->}sz \ne heapbase + (\text{number of mapped pages} \times \text{PGSIZE})}$$
- Between `p->heapbase` and `p->sz`, there can be dozens of untouched "lazy holes" with no physical RAM backing them.

### The Golden Rule of Address Validation:
An address `va` is **only** eligible for lazy allocation if:
$$\mathbf{p\text{->}heapbase} \le \mathbf{va} < \mathbf{p\text{->}sz}$$
- If $va < \text{heapbase}$: It could be the **stack guard page** or code! Touching it must **kill the process**, NOT allocate memory!
- If $va \ge \text{p->sz}$: It is an out-of-bounds pointer beyond what `sbrk()` reserved. The kernel must **kill the process**!

---

## 1.3 The 4 Graded Tasks (K1, K2, K3, K4)

### Task K1: `growproc(int n)` in `kernel/proc.c`
Implements `sbrk()`:
1. **Growing the heap (`n > 0`):**
   ```c
   uint64 newsz = sz + (uint64)n;
   if (newsz < sz || newsz > USYSINFO_VA)
       return -1;
   p->sz = newsz; // Just update virtual boundary! NO palloc(), NO PTEs!
   return 0;
   ```
2. **Shrinking the heap (`n < 0`):**
   ```c
   uint64 dec = (uint64)(-(int64)n);
   if (dec > sz || sz - dec < p->heapbase) // Never shrink below heapbase!
       return -1;
   uint64 newsz = sz - dec;
   if (PGROUNDUP(newsz) < PGROUNDUP(sz)) {
       uvmunmap(p->pagetable, PGROUNDUP(newsz),
                (PGROUNDUP(sz) - PGROUNDUP(newsz)) / PGSIZE, 1);
       sfence_vma();
   }
   p->sz = newsz;
   return 0;
   ```
   *Note:* `uvmunmap()` skips missing PTEs cleanly, so shrinking over unmapped lazy holes does not crash.

---

### Task K2: `lazy_alloc_page(p, va)` in `kernel/vm.c`
The single worker that materializes exactly one page:
1. **Validate range:** Verify $p\text{->heapbase} \le va < p\text{->sz}$.
2. **Page-align:** `va = PGROUNDDOWN(va);`
3. **Check for existing mapping:** Walk PTE; if `*pte & PTE_V` is already valid, return `-1` (this was a permission fault, not a missing lazy page!).
4. **Allocate & Zero:**
   ```c
   char *mem = palloc();
   if (!mem) return -1;
   memset(mem, 0, PGSIZE); // MUST zero for security (no data leaks)!
   ```
5. **Install mapping:**
   ```c
   mappages(p->pagetable, va, PGSIZE, (uint64)mem, PTE_R | PTE_W | PTE_U);
   sfence_vma(); // Flush TLB
   return 0;
   ```

---

### Task K3: User Trap Handling in `kernel/trap.c`
Handles CPU exceptions on user load/store instructions:
1. When a user instruction accesses an unmapped lazy page, the hardware MMU triggers:
   - `scause == 13` (Load Page Fault) or `scause == 15` (Store Page Fault).
   - `stval`: The faulting virtual address.
   - `sepc`: The exact address of the instruction that caused the fault.
2. In `usertrap()`:
   ```c
   else if (scause == 15 || scause == 13) {
       uint64 va = r_stval();
       if (lazy_alloc_page(p, va) != 0) {
           printf("usertrap: killing pid %d\n", p->pid);
           p->killed = 1; // Illegal access (e.g. guard page)
       }
   }
   ```
3. **The Magic Retry (`sret`):**
   - If `lazy_alloc_page()` succeeds, `usertrap()` returns via `sret`.
   - `sret` returns to `sepc` (the **exact same instruction** that faulted).
   - The CPU re-executes the instruction. This time the PTE exists, so it completes silently!

---

### Task K4: Kernel Copy Boundary (`user_resolve_pa()`) in `kernel/vm.c`
#### Why is K4 needed?
Consider:
```c
char *buf = sbrk(4096); // Lazily reserved, no PTE yet!
read(fd, buf, 100);     // Passed to kernel syscall!
```
The user never loaded/stored to `buf` in user mode, so **no user page fault occurred**!  
Instead, the **kernel** itself tries to copy file data into `buf` using `copyout()`.  
If `copyout()` simply rejected unmapped pages, `read()` would fail on a valid buffer!

#### Solution in `user_resolve_pa()`:
```c
pte_t *pte = walk(pt, va, 0);
if (!pte || !(*pte & PTE_V)) {
    struct proc *p = myproc();
    // Only materialize if examining the CURRENT process's own page table!
    if (p && pt == p->pagetable) {
        if (lazy_alloc_page(p, va) == 0) {
            pte = walk(pt, va, 0); // Re-fetch installed PTE!
        }
    }
}
if (!pte || !(*pte & PTE_V) || !(*pte & PTE_U))
    return 0;
if (need_write && !(*pte & PTE_W))
    return 0; // Enforce write permissions (keeps USYSINFO read-only)
return PTE2PA(*pte);
```

---

## 1.4 High-Yield Viva Questions for Lab 4

### Q1: Why do we zero out the physical page with `memset(mem, 0, PGSIZE)`?
**Security / Information Leakage:** Physical pages are recycled from freed memory. If you don't zero the page, the new process can read residual sensitive data left behind by an old process (passwords, encryption keys, private files).

### Q2: Why does `sret` re-execute the faulting instruction instead of skipping to the next one?
Because the faulting instruction (e.g. `ld a0, 0(s1)`) **never actually finished**! It stopped midway because the MMU couldn't translate the address. Skipping it would skip the read/write entirely. After the kernel installs the PTE, the instruction must be retried so the program gets its data.

### Q3: Why can't we just lazily allocate *any* address that page faults?
Because page faults are also triggered by **illegal accesses**:
- Accessing address `0x0` (NULL pointer dereference).
- Accessing the **stack guard page** (stack overflow).
- Accessing random unmapped kernel/user memory.  
If you allocated memory for *any* fault, bugs and stack overflows would silently allocate garbage memory instead of crashing! Only addresses in `[heapbase, sz)` are legal heap addresses.

### Q4: What happens during `fork()` with a lazy heap?
`uvmcopy()` copies the page table to the child. If a page has a valid PTE, it duplicates the physical page. If a page is a "lazy hole" (reserved by `sbrk` but never touched), `uvmcopy()` simply skips it. The child inherits the same `heapbase` and `sz`, so if the child later touches that page, it will trigger its own page fault and get its own independent physical page!

---

# LAB 5: Concurrency, Locks, and Sleep/Wakeup

## 2.1 Race Conditions & Lost Updates
- **Read-Modify-Write (RMW):** A high-level statement like `counter++` is **not atomic**. At the hardware/assembly level, it translates to three discrete instructions:
  1. `LOAD`: Read the current value of `counter` from RAM into a CPU register.
  2. `MODIFY`: Increment the register value by 1.
  3. `STORE`: Write the register value back to RAM.

### The Lost-Update Interleaving Diagram
Suppose `counter = 20`. Thread 1 and Thread 2 run concurrently:
```
Thread 1 (Hart 0)              Thread 2 (Hart 1)             Memory (counter)
-----------------              -----------------             ----------------
1. LOAD counter (sees 20)                                    20
                               2. LOAD counter (sees 20)     20
3. ADD 1 (r1 = 21)                                           20
                               4. ADD 1 (r2 = 21)            20
5. STORE 21 into counter                                     21
                               6. STORE 21 into counter      21  <-- Lost Update!
```
*Outcome:* 2 increments were executed, but `counter` ended at `21` instead of `22`.

### Why `volatile` Does NOT Fix Race Conditions
- `volatile` only instructs the compiler not to optimize away reads/writes and not to keep the variable cached in CPU registers across statements.
- It **does not provide atomicity** for compound Read-Modify-Write sequences. Both threads will still read memory at the same time and overwrite each other.

---

## 2.2 Hardware Atomicity & Spinlocks
A naive software flag:
```c
while (lk->locked) ; // Spin until free
lk->locked = 1;      // Claim lock
```
**Fails completely on multi-core:** If Hart 0 and Hart 1 read `lk->locked == 0` at the exact same cycle, both exit the loop, both write `1`, and both enter the critical section simultaneously!

### LUIT's Spinlock Solution (`kernel/spinlock.c`)
The transition from *reading free* to *claiming* must be atomic at the silicon level:
```c
while (__sync_lock_test_and_set(&lk->locked, 1) != 0)
    ;
```
- In RISC-V, this compiles to atomic instructions such as `amoswap.w.aq` (Atomic Memory Operation: Swap Word with Acquire semantics).
- It atomically writes `1` to `lk->locked` and returns the **old value** in a single instruction.
- If the old value was `0`, the caller won the lock. If it was `1`, someone already holds it, so the caller spins.

### Memory Fences (`__sync_synchronize()`)
Modern out-of-order CPUs and optimizing compilers can reorder instructions for performance.
- A **memory barrier/fence** ensures memory operations inside the critical section cannot be reordered before the lock acquisition or after the lock release.

---

## 2.3 Interrupt Discipline & Same-Hart Deadlock

### The Same-Hart Self-Deadlock Scenario
1. Hart 0 calls `acquire(&lock)`.
2. A timer or device interrupt arrives on Hart 0.
3. The interrupt handler executes on Hart 0 and tries to call `acquire(&lock)` on the **exact same lock**.
4. **DEADLOCK:**
   - The interrupt handler spins forever waiting for the lock to be released.
   - But the original code holding the lock can never run because the interrupt handler is preempting it on the same core!

> **Key Distinction for Viva:**
> - **Atomic instruction (`amoswap`)** prevents **cross-hart races** (another CPU core).
> - **Disabling local interrupts (`push_off`)** prevents **same-hart interrupt deadlock** (interrupt handler on the same core). Disabling interrupts on Core 0 does *not* protect against Core 1!

### Nested Interrupt Tracking (`push_off()` / `pop_off()`)
Locks can be nested (e.g., acquiring Lock A, then acquiring Lock B).
- A naive `intr_on()` on `release(&Lock_B)` would prematurely re-enable interrupts while Lock A is still held!
- `push_off()` records the original interrupt state on the first call (`c->noff == 0`) and increments `c->noff`.
- `pop_off()` decrements `c->noff` and **only re-enables interrupts when `c->noff == 0`**.

---

## 2.4 Sleep / Wakeup & The Lost-Wakeup Bug

### Spinning vs. Sleeping
- **Spinlock:** For **short** waits (a few clock cycles). The core stays active and wastes CPU cycles.
- **Sleep:** For **long/unbounded** waits (disk I/O, waiting for a pipe reader). The process yields the CPU via `sched()` so other processes can execute.

### What is a Sleep Channel (`chan`)?
In LUIT/xv6, a channel is simply an **arbitrary memory address** used as a unique identifier (tag) to group sleeping processes. `wakeup(chan)` wakes up all processes whose `p->chan == chan`.

---

### The Lost-Wakeup Bug (Crucial Viva Question)
Suppose we separated unlocking from sleeping:
```c
acquire(&lock);
while (!condition) {
    release(&lock);
    sleep_somehow(chan); // <-- DANGEROUS WINDOW!
    acquire(&lock);
}
```
#### The Fatal Interleaving:
```
Waiter (Process A)                    Signaler (Process B)
------------------                    --------------------
1. acquire(&lock)
2. checks condition -> FALSE
3. release(&lock)
   [RACE WINDOW / CONTEXT SWITCH]
                                      4. acquire(&lock)
                                      5. makes condition TRUE
                                      6. calls wakeup(chan) (Nobody is sleeping yet! Wakeup is LOST!)
                                      7. release(&lock)
8. sleep_somehow(chan)
```
- Process B's wakeup arrived in the gap before Process A marked itself as sleeping.
- **Process A now sleeps forever**, even though the condition is TRUE!

#### How `sleep(chan, lock)` Solves This:
```c
void sleep(void *chan, struct spinlock *lk)
{
    struct proc *p = myproc();
    acquire(&p->lock);  // 1. Grab process's own lock
    release(lk);        // 2. Safely release the condition lock

    p->chan = chan;
    p->state = SLEEPING;
    sched();            // 3. Switch CPU to scheduler

    p->chan = 0;
    release(&p->lock);
    acquire(lk);        // 4. Re-acquire condition lock upon return
}
```
Because `p->lock` is acquired **before** `lk` is released, any signaler calling `wakeup(chan)` must acquire `p->lock` to mark `p->state = RUNNABLE`. It cannot slip into the gap!

### Why Waiting Must Be Inside a `while` Loop (Never `if`!)
```c
while (!condition)
    sleep(chan, &lock);
```
When `sleep()` returns, it has re-acquired the lock, but:
1. Another process might have woken up first, acquired the lock, and consumed the available resource.
2. `wakeup()` might wake multiple waiters for only 1 available resource.
3. Therefore, the woken process **must re-verify that the condition is still true** before proceeding.

---

## 2.5 Bounded Pipe Concurrency Case Study
In [`kernel/pipe.c`](file:///home/hp/luitos/Lab06/kernel/pipe.c):
- `data[PIPESIZE]` ring buffer (512 bytes).
- **Writer blocks** when full: `pi->nwrite == pi->nread + PIPESIZE`. Sleeps on `&pi->nwrite`.
- **Reader wakes writers** after consuming bytes: `wakeup(&pi->nwrite)`.
- **Reader blocks** when empty: `pi->nread == pi->nwrite`. Sleeps on `&pi->nread`.
- **Writer wakes readers** after producing bytes: `wakeup(&pi->nread)`.

---

# LAB 6: Bounded Blocking Mailboxes

## 3.1 Subsystem Design & State Representation
In [`kernel/mailbox.c`](file:///home/hp/luitos/Lab06/kernel/mailbox.c):
- `NMAILBOX = 8`, `MBOX_CAP = 8`.
- Ring buffer storing non-negative integers ($0 \le \text{value} \le 2^{31}-1$).

```c
struct mailbox {
    struct spinlock lock; // Dedicated spinlock per mailbox
    int data[MBOX_CAP];   // Circular queue
    int head;             // Index of oldest item (next to read)
    int tail;             // Index of next free slot (next to write)
    int count;            // Number of items in buffer (0 <= count <= 8)
    int closed;           // Permanent close flag (1 = closed)
    char rchan;           // Channel address for blocked receivers
    char wchan;           // Channel address for blocked senders
};
```

---

## 3.2 Sleep Channels (`rchan` vs `wchan`)
- `rchan` and `wchan` are dummy fields. Their values are never read or written.
- Their **memory addresses** (`&mb->rchan` and `&mb->wchan`) provide two distinct sleep channels.
- **Why two channels?** To achieve **directed wakeups**.
  - Senders wake receivers on `&mb->rchan`.
  - Receivers wake senders on `&mb->wchan`.
  - If a single channel were used, waking a sleeper might wake another sender instead of a receiver, causing deadlock or wasted CPU wakeups.

---

## 3.3 Operation Walkthroughs (Send, Recv, Close)

### `mbox_send(id, value)`
1. Validates ID ($0 \le id < 8$) and value ($\ge 0$).
2. Acquires `mb->lock`.
3. Waits while full AND open:
   ```c
   while (mb->count == MBOX_CAP && !mb->closed)
       sleep(&mb->wchan, &mb->lock);
   ```
4. If closed (either initially or while sleeping), returns `-1`.
5. Inserts value into circular buffer:
   ```c
   mb->data[mb->tail] = value;
   mb->tail = (mb->tail + 1) % MBOX_CAP;
   mb->count++;
   ```
6. Calls `wakeup(&mb->rchan)` to wake blocked receivers.
7. Releases lock and returns `0`.

---

### `mbox_recv(id)`
1. Validates ID.
2. Acquires `mb->lock`.
3. Waits while empty AND open:
   ```c
   while (mb->count == 0 && !mb->closed)
       sleep(&mb->rchan, &mb->lock);
   ```
4. **Checks for End-of-Stream:**
   ```c
   if (mb->count == 0) { // Can only be 0 here if mb->closed == 1
       release(&mb->lock);
       return -1;
   }
   ```
5. Reads and removes oldest value:
   ```c
   v = mb->data[mb->head];
   mb->head = (mb->head + 1) % MBOX_CAP;
   mb->count--;
   ```
6. Calls `wakeup(&mb->wchan)` to wake blocked senders.
7. Releases lock and returns `v`.

---

### `mbox_close(id)`
1. Validates ID.
2. Acquires `mb->lock`.
3. Sets `mb->closed = 1`.
4. Wakes **BOTH** channels:
   ```c
   wakeup(&mb->rchan); // Wakes receivers waiting on empty queue -> they see closed & return -1
   wakeup(&mb->wchan); // Wakes senders waiting on full queue -> they see closed & return -1
   ```
5. Releases lock and returns `0`.

---

## 3.4 Critical Edge Cases & Common Traps

### Q: Why does `close()` NOT set `count = 0`?
- **"Drain Before End-of-Stream" Semantics:** Existing buffered messages must **never be discarded** on close.
- A producer may send 3 messages and close the mailbox. The consumer must still be able to receive all 3 messages before receiving `-1`.

### Q: Why must `close()` wake BOTH senders and receivers?
- Blocked receivers on an empty queue can never get new data. They must wake to return `-1`.
- Blocked senders on a full queue can never get buffer space (and sends on closed mailboxes are illegal anyway). They must wake to return `-1`.
- If either channel were omitted, that class of threads would hang in kernel sleep indefinitely!

### Q: Why per-mailbox locks rather than one global mailbox lock?
- Concurrency! Operations on Mailbox 0 do not contend with or block operations on Mailbox 7.

---

# LAB 7: Deterministic Proportional-Share (Stride) Scheduling

## 4.1 Stride Scheduling Fundamentals & Mathematical Proof

### Core Parameters (per process)
- **`tickets` ($T$):** User/OS allocation ($1 \le T \le 1000$, default $100$).
- **`stride` ($S$):** Step size:
  $$S = \left\lfloor\frac{\text{STRIDE\_BIG}}{T}\right\rfloor = \left\lfloor\frac{10{,}000{,}000}{T}\right\rfloor$$
- **`pass` ($P$):** Virtual time accumulation. Each time process is dispatched:
  $$P \leftarrow P + S$$

### Selection Rule
Always dispatch the `RUNNABLE` process with the **minimum `sched_pass`**.

### Mathematical Proof of Proportional Share
Let Process A have $T_A = 200$ tickets and Process B have $T_B = 100$ tickets.
- $S_A = 10{,}000{,}000 / 200 = 50{,}000$
- $S_B = 10{,}000{,}000 / 100 = 100{,}000$

Whenever A runs, its pass advances by $50{,}000$. Whenever B runs, its pass advances by $100{,}000$.
To maintain the minimum pass property, the scheduler must pick Process A **twice** for every **one** time it picks Process B:
$$\frac{\text{Dispatches}_A}{\text{Dispatches}_B} = \frac{S_B}{S_A} = \frac{T_A}{T_B} = \frac{200}{100} = 2$$
The CPU allocation is mathematically exact and deterministic.

---

## 4.2 The 3 Classic Pitfalls & How LUIT Solves Them

### 1. New Arrival / Fork Cheating (S1, S2)
- **Problem:** If a new process started with `pass = 0`, it would dominate the CPU until it reached the pass of existing processes. A process could spam `fork()` to monopolize the system.
- **Solution:** Maintain a global `stride_floor` (the pass of the most recently scheduled process).
  - In `allocproc()` (`S1`): `p->sched_pass = stride_floor_snapshot()`.
  - In `fork()` (`S2`): Child inherits parent tickets/stride, and:
    $$\text{child}->\text{sched\_pass} = \max(\text{parent}->\text{sched\_pass}, \text{stride\_floor})$$

---

### 2. Stale Sleeper / Wakeup Catch-up (S5, S6)
- **Problem:** A process sleeps on disk I/O for 10 seconds. Its `pass` stayed at 100 while running processes advanced to 5,000,000. If it woke with pass 100, it would starve all other processes for thousands of dispatches.
- **Solution (Pass Clamping):** In `wakeup()` and `kill()`:
  ```c
  uint64 floor = stride_floor_snapshot();
  if (p->sched_pass < floor)
      p->sched_pass = floor;
  p->state = RUNNABLE;
  ```

---

### 3. Dynamic Ticket Changes (`set_tickets()`, S3)
- **Problem:** What happens if a process calls `settickets(new_tickets)`?
- **Solution:**
  ```c
  p->sched_tickets = tickets;
  p->sched_stride = STRIDE_BIG / tickets;
  ```
  - **`sched_pass` is KEPT UNCHANGED.**
  - Resetting `pass` would erase CPU usage history and allow unfairness exploits.

---

## 4.3 SMP Selection Algorithm & Locking Contract (`stride_pick_next()`, S4)

### The SMP Selection Steps
1. Acquire global `stride_lock`.
2. Iterate through `proc[]`. For each process:
   - Acquire `p->lock`.
   - Check if `p->state == RUNNABLE`.
   - Release `p->lock` (*never hold two process locks at once during scanning!*).
3. Select best candidate using **3-Tier Tie-Breaker**:
   - **Tier 1:** Smallest `sched_pass`.
   - **Tier 2 (Affinity):** If pass is equal, prefer process whose `sched_last_hart == current_hart` (keeps CPU caches warm).
   - **Tier 3 (Determinism):** If still tied, prefer smaller `pid`.
4. Re-acquire `best->lock`. Verify `best->state == RUNNABLE`.
5. Publish new floor: `stride_floor_publish(best->sched_pass)`.
6. Update stats: `sched_dispatches++`, track `sched_migrations`, update `sched_last_hart`.
7. Advance pass: `best->sched_pass += best->sched_stride`.
8. Set `best->state = RUNNING`.
9. **Release `stride_lock` before returning `best` with `best->lock` held.**

> **Critical Viva Question:** *Why must `stride_lock` NEVER be held across `swtch()`?*  
> **Answer:** If Core 0 held `stride_lock` while executing a user process, **no other CPU core could run `stride_pick_next()` to make a scheduling decision!** The entire multicore system would freeze!

---

## 4.4 Summary of Lab 7 Implementation Regions (S1–S6)

| Region | Function | Key Action |
| :--- | :--- | :--- |
| **S1** | `allocproc()` | Initialize default tickets (100), compute stride, reset stats, set `pass = stride_floor`. |
| **S2** | `fork()` | Child inherits tickets & stride; pass set to $\max(\text{parent}, \text{floor})$; stats reset to 0. |
| **S3** | `set_tickets()` | Validate $1 \le n \le 1000$; update tickets and stride; **preserve existing pass**. |
| **S4** | `stride_pick_next()` | Acquire `stride_lock`; find min-pass process with affinity/PID tie-breakers; publish floor; charge stride; update stats; release `stride_lock`. |
| **S5** | `wakeup()` | When waking sleeper, clamp pass: `if (pass < floor) pass = floor`. |
| **S6** | `kill()` | If killing wakes a sleeping process, apply identical pass clamping. |
