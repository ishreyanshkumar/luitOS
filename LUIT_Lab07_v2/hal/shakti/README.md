# SHAKTI backend (stub)

Compiles, boots to the SBI console, then stops at the first unimplemented
device. Nothing here pretends to be tested hardware support: no register map
in this directory was copied from a datasheet yet, because inventing one would
be worse than useless. Lab 12 teams fill this in against real documentation,
one device at a time (UART -> PLIC -> block), validating each on the bench.
