section .multiboot_header
MBH_start:
    dd 0xe85250d6                ; magic number (multiboot 2)
    dd 0                         ; architecture 0 (protected mode i386)
    dd MBH_end - MBH_start       ; header length
    
    ; checksum
    dd 0x100000000 - (0xe85250d6 + 0 + (MBH_end - MBH_start))

    ; optional multiboot tags here

    ; required end tag
    dw 0    ; type
    dw 0    ; flags
    dd 8    ; size
MBH_end:
