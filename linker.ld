ENTRY(_start)
OUTPUT_FORMAT(binary)

SECTIONS {
    .bootsector : {
        *(.bootsector)
    }
    
    .text : {
        *(.text)
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
    }
}

