; Hello World, but with symbols

section .text	; implicit

_start:
	mov eax 0x1		; write syscall
	mov edi 0x1		; stdout
	mov esi msg		; string to print
	mov edx len		; length
	syscall

exit:
	mov eax 60		; exit syscall
	mov edi 0		; exit code
	syscall

section .rodata

msg:
	db "Hello, World!" 0xa
len:
	eq 14

