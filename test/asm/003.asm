; Hello World

section .text ; implicit

_start:
	mov eax 0x1		; write syscall
	mov edi 0x1		; stdout
	mov esi msg
	mov edx len		; length
	syscall

	mov eax 60
	mov edi 0
	syscall

section .rodata

msg:
	db "Hello, World!" 0xa
len:
	eq 14

