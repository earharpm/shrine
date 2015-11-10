global start

section .text
bits 32 ; still in Protected Mode
start:
	; prints OK to the screen
	mov dword [0xb8000], 0x2f4b2f4f
