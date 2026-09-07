# Release Engineering — CS3106L / LUIT

*Dr. Satyajit Das · Department of Computer Science and Engineering · IIT Guwahati*

## Branch model

    master                 development trunk (staff-only; contains references)
    release/base-v1.0       the clean Teaching Base students receive on day one
    release/lab01 .. lab12  per-lab student starting points (skeletons + specs, NO solutions)
    staff/solution-lab01..  per-lab reference solutions + hidden tests (NEVER published)

`release/labNN` is what a student clones to begin lab N. It contains that lab's
handout (`docs/labs-v2/labNN.md`), starter skeletons, public tests, and the
baseline — but not the reference implementation, hidden tests, or grading scripts.

`staff/solution-labNN` contains the reference implementation, hidden tests,
expected outputs, common-bug patches, and viva guidance.

## Producing a clean student release (critical)

The public student repository MUST NOT contain solutions, solution patches,
hidden tests, private grading scripts, or historical commits exposing solutions.
Because `master` and the `staff/*` branches contain reference code, a student
release is built from a **squashed or orphan commit**, not by branching master:

    # from a clean checkout of release/base-v1.0 + the lab NN skeletons only:
    git checkout --orphan student-labNN
    git add <baseline + labNN skeletons + labNN.md + public tests only>
    git commit -m "CS3106L Lab NN student release"
    # push student-labNN to the student-facing remote

This guarantees no solution is reachable through history. Never push `master` or
`staff/*` to a student-visible remote.

## What is in each release (checklist)

Student `release/labNN`:
- [x] baseline kernel + build system
- [x] `docs/labs-v2/labNN.md` (the handout)
- [x] starter skeletons (in `staff/skeletons/` moved to their kernel/user homes)
- [x] public tests `tests/labNN_*.sh`
- [ ] NO reference code, NO hidden tests, NO grade.py internals beyond public

Staff `staff/solution-labNN`:
- [x] reference implementation (`staff/reference/`)
- [x] hidden tests
- [x] expected outputs / performance baselines
- [x] common-bug patches, viva guidance

## Verification gate before any release

    git status --porcelain     # must be empty before and after a clean build
    make clean && make -j       # parallel build must succeed
    make grade                  # baseline 9/9
    make grade LAB=NN           # lab NN public checks pass

## Current state

Branches `release/lab01..12` and `staff/solution-lab01..12` exist as markers off
the current trunk. As each lab's student skeleton and staff solution are
finalised, the respective branches are populated per the model above. Labs with
verified reference code today: 1, 2, 3, 5, 6.
