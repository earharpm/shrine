global start

section .text
bits 32 ; still in Protected Mode
start:
	mov esp, stack_top

	; Make sure the system is valid
	call test_multiboot
	call test_cpuid
	call test_long_mode

	call setup_page_tables
	call enable_paging

	; prints OK to the screen
	mov dword [0xb8000], 0x2f4b2f4f
	hlt

; Prints `ERR: ` and the given error code to screen and hangs.
; parameter: error code (in ascii) in al
error:
    mov dword [0xb8000], 0x4f524f45
    mov dword [0xb8004], 0x4f3a4f52
    mov dword [0xb8008], 0x4f204f20
    mov byte  [0xb800a], al
    hlt


test_multiboot:
	cmp eax, 0x36d76289
	jne .no_multiboot
	ret
.no_multiboot:
	mov al, "0"
	jmp error

; Taken from OSDev wiki
test_cpuid:
    pushfd               ; Store the FLAGS-register.
    pop eax              ; Restore the A-register.
    mov ecx, eax         ; Set the C-register to the A-register.
    xor eax, 1 << 21     ; Flip the ID-bit, which is bit 21.
    push eax             ; Store the A-register.
    popfd                ; Restore the FLAGS-register.
    pushfd               ; Store the FLAGS-register.
    pop eax              ; Restore the A-register.
    push ecx             ; Store the C-register.
    popfd                ; Restore the FLAGS-register.
    xor eax, ecx         ; Do a XOR-operation on the A-register and the C-register.
    jz .no_cpuid         ; The zero flag is set, no CPUID.
    ret                  ; CPUID is available for use.
.no_cpuid:
    mov al, "1"
    jmp error

; Taken from OSDev wiki
test_long_mode:
    mov eax, 0x80000000    ; Set the A-register to 0x80000000.
    cpuid                  ; CPU identification.
    cmp eax, 0x80000001    ; Compare the A-register with 0x80000001.
    jb .no_long_mode       ; It is less, there is no long mode.
    mov eax, 0x80000001    ; Set the A-register to 0x80000001.
    cpuid                  ; CPU identification.
    test edx, 1 << 29      ; Test if the LM-bit, which is bit 29, is set in the D-register.
    jz .no_long_mode       ; They aren't, there is no long mode.
    ret
.no_long_mode:
    mov al, "2"
    jmp error


setup_page_tables:
	; Map the first P4 entry to P3
	mov eax, p3_table
	or eax, 0b11 ; present + writable
	mov [p4_table], eax

	; Map the first P3 entry to P2
	mov eax, p2_table
	or eax, 0b11 ; present + writable
	mov [p3_table], eax

	; Map each P2 entry to a 2MiB page
	mov ecx, 0

.map_p2_table:
	; Map the /ecx/-th P2 entry to a huge page (2MiB)
	mov eax, 0x200000	; 2MiB
	mul ecx
	or eax, 0b10000011	; present + writable + huge
	mov [p2_table + ecx * 8], eax ; map ecx-tf entry

	; Because looping in asm....
	inc ecx
	cmp ecx, 512
	jne .map_p2_table

	ret

enable_paging:
	; Load P4 to cr3 register (cpu access to the P4 table)
	mov eax, p4_table
	mov cr3, eax

	; enable PAE-flag in cr4 (Physical Address Extension)
	mov eax, cr4
	or eax, 1 << 5
	mov cr4, eax

	; set the long mode bit in the EFER SMR (model specific register)
	mov ecx, 0xC0000080
	rdmsr
	or eax, 1 << 8
	wrmsr

	; enable paging in the cr0 register
	mov eax, cr0
	or eax, 1 << 31
	or eax, 1 << 16
	mov cr0, eax

	ret


section .bss
align 4096
p4_table: 		; Page-Map L4 Table (PLM4)
	resb 4096
p3_table:		; Page-Directory Pointer Table (PDP)
	resb 4096
p2_table:		; Page-Directory Table (PD)
	resb 4096
p1_table:		; Page Table (PT)
	resb 4096
stack_bottom:
	resb 64
stack_top
