; exit code 42, with more instructions

; mov eax 1
xor eax eax
add eax -1
dec eax
inc eax
neg eax

; mov ebx 42
mov ecx 45
sub ecx 2
sub ecx eax
xor ebx ebx
add ebx ecx

; syscall
int 0x80

