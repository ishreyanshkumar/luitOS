#!/bin/sh
# Kept as a shell wrapper so tests/run_lab.sh discovers the Lab 3 test exactly
# as before.  The actual driver is Python so it can synchronize with QEMU
# output instead of relying on machine-dependent sleep durations.
exec python3 tests/lab03_usysinfo.py
