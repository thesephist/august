; scratch

xor eax eax
inc eax
mov ebx 42 ; comment
int 0x80

; section .text ; implicit
; 
; _start:
; 	mov eax 0x1		; write syscall
; 	mov edi 0x1		; stdout
; 	mov esi msg
; 	mov edx len		; length
; 	syscall
; 
; 	mov eax 60
; 	mov edi 0
; 	syscall
; 
; section .rodata
; 
; msg:
; 	"Hello, World!" 0xa
; len:
; 	14

