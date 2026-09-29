#!/bin/sh
# Embed ONLY initcode into the kernel image. (Everything else now lives on
# the LuitFS disk - this replaced tools/genbinaries.sh, which embedded every
# user program back when there was no filesystem.)
cat << 'ASM'
.section .rodata
.globl _binary_user_initcode_start
.globl _binary_user_initcode_end
_binary_user_initcode_start:
.incbin "user/initcode"
_binary_user_initcode_end:
ASM
