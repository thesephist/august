; Hello World

section .text	; implicit

mov eax 0x1		; write syscall
mov edi 0x1		; stdout
mov esi msg_a
mov edx len_a	; length
syscall

xor eax eax
inc eax
mov edi eax
mov esi msg_b
mov edx len_b	; length
syscall

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
