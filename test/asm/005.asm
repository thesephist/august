; compares and jumps

_start:
	; if 0, says hello world
	; if 1, says goodbye
	mov eax 0
	cmp eax 0

	mov eax 0x1		; write syscall
	mov edi 0x1		; stdout

	jne goodbye

hello:
	mov esi msg_a
	mov edx len_a	; length
	syscall

	jmp exit

goodbye:
	mov esi msg_b
	mov edx len_b	; length
	syscall

	jmp exit

exit:
	mov eax 60
	mov edi 0
	syscall

section .rodata

msg_a:
	db "Hello, World!" 0xa
len_a:
	eq 14

msg_b:
	db "Goodbye!" 10
len_b:
	eq 9

