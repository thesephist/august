; Hello World pyramid: loops, conditionals, calls

_start:
	; load argument and call

	; mov rdi msg
	xor eax eax
	mov ebx 0
	lea edi [ebx 8 eax msg]

	; mov rsi len
	xor esi esi
	mov eax len
	mov esi, len
	call print_hello

exit:
	mov eax 60
	mov edi 0
	syscall

print_hello:
	mov rdx rsi ; 2nd arg
	mov rsi rdi ; 1st arg

	mov eax 0x1
	mov edi 0x1
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

