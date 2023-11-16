.code16

.globl _start
_start:
    cli

    movb $0x3, %al
    movb $0x0, %ah
    int $0x10 // Set video mode: 80x25 vga

    movw $0x07C0, %ax
    movw %ax, %ds
    movw %ax, %ss

    // Stack will be placed at 0x7C00 + 0x400 (two sectors after bootsector)
    movw 0x400, %sp

    cld

hang:
    jmp hang

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

.org 510
.byte 0x55, 0xAA
