# CS3106L Lab 7 - Stride Scheduling in LUIT

This is a **complete standalone LUIT Lab 7 checkpoint**. It already includes the
kernel, user programs, HAL, filesystem builder, top-level `Makefile`, completed
dependencies from earlier labs (including the Lab 6 mailbox implementation),
Lab 7 public tests, checking tools, and the Lab 7 handout.

**Do not copy files from an older LUIT tree or from xv6.**

Read first:

- `docs/CS3106L_Lab07_Handout.pdf`

The only Lab 7 implementation file that may be edited is:

- `kernel/proc.c` - regions S1-S6 and the explicit `LAB7-HELPERS` region only.

## First verification

```sh
python3 tools/lab07_check.py
make clean
make
make grade
```

The untouched checkpoint is intended to build and preserve the earlier-course
baseline. The Lab 7 stride policy itself is intentionally incomplete.

## Lab 7 public tests

```sh
make grade LAB=7
```

A faster direct run is:

```sh
python3 tests/grade_lab07.py --quick
```

## Submission archive

After the public suite passes:

```sh
python3 tools/package_lab07.py YOUR_NINE_DIGIT_ROLL
```

This creates `YOUR_NINE_DIGIT_ROLL_Lab07.zip` containing only
`kernel/proc.c` under the roll-numbered directory. The packager creates its
temporary archive inside this repository, so no `TMPDIR` workaround is needed.
