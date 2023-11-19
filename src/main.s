.code16

second_stage:
    movw $0x07c0, %ax
    movw %ax, %ds

    movw $msg, %si
    call print_str

    

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

