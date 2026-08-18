# Luit Lab 1 Student Distribution

**CS3106L - Operating Systems: Concepts and Construction**  
Department of Computer Science and Engineering, IIT Guwahati

This repository is the student starter for **Lab 1: User Programs, Processes,
Pipes, and the Luit System-Call Boundary**.

## Start here

1. Read `docs/labs/LUIT_Lab01_Student_Handout.pdf` completely.
2. From the repository root, run:

   ```bash
   make clean
   make
   make lab01-check
   ```

3. Complete only the numbered TODO regions in:

   - `user/sleep.c`
   - `user/pingpong.c`
   - `user/pstree.c`
   - `tools/syscallmap.py`

4. Complete the evidence files in `lab01/`:

   - `README.txt`
   - `report.tex`
   - `gdb-trace.txt`
   - `LLM_LOG.md`

5. Test your work according to the handout, including the public regression
   tests and the required one-hart and four-hart runs.
6. Create the submission archive using your exact nine-digit roll number:

   ```bash
   python3 tools/package_lab01.py YOUR_9_DIGIT_ROLL_NUMBER
   ```

7. Upload only the generated `ROLLNUMBER_Lab01.zip` to the official OneDrive
   file-request link before the deadline announced in the lab.

## Files you may edit

You may edit the four implementation files listed above and the evidence files
under `lab01/`. You may add helper functions, constants, and local data
structures inside the four implementation files.

Do not modify the kernel, Makefile, generated syscall files, public tests,
release-integrity checker, or packaging utility unless the handout explicitly
instructs you to do so.

## Windows/WSL metadata

If the repository was downloaded or extracted through Windows, files named
`*:Zone.Identifier` may appear inside WSL. They are Windows download-security
metadata, not Luit source files. Release v1.3.2 ignores these files during
`make lab01-check`. They can also be removed safely with:

```bash
make lab01-clean-metadata
```

Do not manually add these metadata files to the submission ZIP. The official
packaging utility includes only the required submission files.

## Useful commands

```bash
make                    # build the kernel and filesystem image
make qemu CPUS=1        # boot with one hart
make qemu CPUS=4        # boot with four harts
make qemu-gdb CPUS=1    # boot paused for GDB
make grade              # run public baseline regression tests
make lab01-check        # check protected release files
make lab01-clean-metadata # remove Windows/macOS metadata files
python3 tools/syscallmap.py
```

To quit QEMU, press `Ctrl-A`, release it, and then press `X`.
