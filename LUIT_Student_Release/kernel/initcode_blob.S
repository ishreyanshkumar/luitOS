.section .rodata
.globl _binary_user_initcode_start
.globl _binary_user_initcode_end
_binary_user_initcode_start:
.incbin "user/initcode"
_binary_user_initcode_end:
