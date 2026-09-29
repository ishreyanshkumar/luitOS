# CS3106L - Luit Lab 4

**Fault-Driven Heap Allocation: Lazy `sbrk()`, Page Faults, and Safe Kernel/User Copying**

Start with the student handout:

`docs/CS3106L_Lab04_Student_Handout_v1.0.pdf`

You implement exactly four marked regions:

- K1 in `kernel/proc.c`
- K2 and K4 in `kernel/vm.c`
- K3 in `kernel/trap.c`

Do not place required Lab 4 code outside these regions. The official grader
extracts only K1-K4 into a clean checkpoint.

Use this sequence while working:

```sh
make lab04-check
make clean && make
make grade
make grade LAB=4
```

The unmodified starter is supposed to pass the earlier baseline and fail the
Lab 4 public test. That is not a distribution error.

When finished, create the submission with:

```sh
python3 tools/package_lab04.py YOUR_ROLL_NUMBER
```

Submit only the ZIP created by that command.
