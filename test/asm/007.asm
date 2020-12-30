; Hello World, but stress testing load/store facilities

_start:
	; load argument and call

	; mov rdi msg
	xor eax eax
	mov ebx 0
	lea edi [ebx 8 eax msg]

	; mov rsi [len_addr]
	xor rax rax
	lea ebx [rax 4 rax len_addr] ; load rbx len_addr
	mov esi [ebx 2 rax]
	mov esi [ebx]
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
	add [eax 0x54] ebx
	add edi [ebx]

	nop
	nop

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
len_addr:
	db 13 0 0 0

