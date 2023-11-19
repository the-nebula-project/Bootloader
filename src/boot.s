.code16

.globl _start
_start:
    cli

    movb $0x3, %al
    movb $0x0, %ah
    int $0x10 // Set video mode: 80x25 vga

    movw $0x0, %ax
    movw %ax, %ds
    movw %ax, %ss

    // Stack will be placed at 0x7C00 + 0x2000 (twenty sectors after bootsector)
    movw $0x9C00, %sp
    sti

    movb %dl, boot_disk_number // Store it

    cld

    // Loading the second stage

    // Reloading the floppy controller
    xorw %ax, %ax
    int $0x13

    xorw %bx, %bx
    movw %bx, %ds

    movb $2, %ah // Read from disk
    movb $1, %al // One sector
    movb $0, %ch // Cylinder 0
    movb $2, %cl // Sector 2 (starts from 1)
    movb $0, %dh

    // es:bx is the buffer address
    xorw %bx, %bx
    movw %bx, %es
    movw $0x7E00, %bx 

    int $0x13

    jc .error // If CF is set, error

    movw $0x7E00, %ax
    jmp *%ax

hang:
    jmp hang

.error:
    movw $error_msg, %si
    addw $0x7C00, %si
    call print_str
    cli
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

hex_prefix:
    .byte '0', 'x', 0

// Prints the value in %ax
print_reg:

    movw $0x10, %bx
    movw %ax, reg_storage

    movw $hex_prefix, %si
    addw $0x7C00, %si
    call print_str
    movw $reg_storage, %ax

.loop:
    
    cmpw $0, %ax
    je .loop_end

    divw %bx // Result in %ax, remainder in %dx
    cmpw $9, %dx
    jg .letter

.number:
    addw $'0', %dx

    jmp .print
.letter:
    subw $10, %dx
    addw $'A', %dx

.print:
    movw %ax, %cx
    movb $0x0E, %ah
    movb %dl, %al
    int $0x10
    jmp .loop

.loop_end:
    movw $reg_storage, %ax
    ret

reg_storage:
    .word 0

msg:
    .asciz "Hello"

error_msg:
    .asciz "Error"

boot_disk_number:
    .byte 0

.org 510
.byte 0x55, 0xAA
