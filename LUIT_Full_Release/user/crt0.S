# The user-space C runtime. Without this, ld has no _start, silently defaults
# the entry point to the first byte of .text, and your program begins executing
# in the middle of whatever function happened to land there. (We hit exactly
# that while writing this reference kernel: usertests "started" inside ok().)
.section .text.start
.globl _start
_start:
        call    main
        # main returned - use its value as the exit status
        call    exit
1:      j       1b
