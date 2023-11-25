.code16

#include "defs.h"

second_stage:
    movw $0x07c0, %ax
    movw %ax, %ds

    movw $msg, %si
    call print_str

    // 1. Get the bootloader config
    // 2. Get the memory map
    // 3. Load the kernel
    // 4. Enter protected mode
    // 5. Transfer control to the kernel

halt:
    hlt
    jmp halt

print_str:
    movb $0x0E, %ah
.char:
    lodsb
    orb %al, %al
    jz .done

    int $0x10
    jmp .char
.done:
    ret

.section .data

msg:
    .asciz "Second stage booted"

