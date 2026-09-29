# BrahmaputraOS / Luit - CS3106L Lab 4

This directory is the student checkpoint for the graded Lab 4 exercise on
fault-driven heap allocation.

The kernel in this checkpoint includes the completed dependencies from earlier
labs. Your Lab 4 work is restricted to four marked TODO regions in
`kernel/proc.c`, `kernel/vm.c`, and `kernel/trap.c`.

Please read `docs/CS3106L_Lab04_Student_Handout_v1.0.pdf` before editing the
source. A short command summary is also available in `README_LAB04.md`.

The standard build and test commands are:

```sh
make lab04-check
make clean && make
make grade
make grade LAB=4
```

The starter checkpoint should build and preserve the earlier-course baseline,
but `make grade LAB=4` should fail until the Lab 4 implementation is complete.

Create the final submission with:

```sh
python3 tools/package_lab04.py YOUR_ROLL_NUMBER
```
