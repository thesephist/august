; Hello World

_start:
	mov eax times

loop:
	push eax

	; write hello world
	mov eax 0x1
	mov edi 0x1
	mov esi msg
	mov edx len
	syscall

	pop eax
	cmp eax 1
	je exit

	dec eax
	jmp loop

exit:
	mov eax 60
	mov edi 0
	syscall

section .rodata

times:
	eq 5

msg:
	db "Hello, World!" 0xa
len:
	eq 14

