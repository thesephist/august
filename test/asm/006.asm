; Hello World pyramid: loops, conditionals, calls

_start:
	mov eax 1

loop:
	push eax

	; load argument and call
	mov edi eax
	call print

	pop eax
	cmp eax len
	je exit

	inc eax
	jmp loop

exit:
	mov eax 60
	mov edi 0
	syscall

print:
	mov edx edi

	mov eax 0x1
	mov edi 0x1
	mov esi msg
	syscall

	mov eax 0x1
	mov edi 0x1
	mov esi newline
	mov edx 1
	syscall

	ret

section .rodata

msg:
	db "Hello, World!"
newline:
	db 0xa
len:
	eq 13

