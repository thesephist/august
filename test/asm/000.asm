; Hello World pyramid: loops, conditionals, calls

_start:
	; load argument and call

	; mov rdi msg
	xor eax eax
	mov ebx 0
	lea edi [ebx 8 eax msg]

	; mov rsi len
	xor esi esi
	add esi len
	call print_hello

exit:
	mov eax 60
	mov edi 0
	syscall

	add rax [ebx 4 ecx 0x44]
	mov ax [ebx 4 ecx 0x44]
	add [rbx 4 rcx 0x44] ax
	mov [rbx 4 rcx 0x44] eax
	mov rax rdi
	mov eax edi

print_hello:
	mov rdx rsi ; 2nd arg
	mov rsi rdi ; 1st arg

	mov rax 0x1
	mov rdi 0x1
	syscall

	mov rax 0x1
	mov rdi 0x1
	mov rsi newline
	mov rdx 1
	syscall

	ret

section .rodata

msg:
	db "Hello, World!"
newline:
	db 0xa
len:
	eq 13

