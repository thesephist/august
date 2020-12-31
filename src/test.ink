` assembler (instruction encoder) tests `

std := load('../vendor/std')
str := load('../vendor/str')

log := std.log
f := std.format
cat := std.cat
each := std.each
replace := str.replace

bytes := load('../lib/bytes')

transform := bytes.transform
untransform := bytes.untransform

asm := load('asm')

assemble := asm.assemble

Newline := char(10)

s := (load('../vendor/suite').suite)('August assembler')
m := s.mark
t := s.test

Translations := [
	{
		asm: 'nop'
		code: '90'
	}
	{
		asm: 'xor eax eax'
		code: '31 c0'
	}
	{
		asm: 'mov ebx 0x45'
		code: 'bb 45 00 00 00'
	}
	{
		asm: 'mov rsi 0x90'
		code: '48 c7 c6 90 00 00 00'
	}
	{
		asm: 'mov rax rdi'
		code: '48 89 f8'
	}
	{
		asm: 'mov ax di'
		code: '66 89 f8'
	}
	{
		asm: 'mov esi [ebx]'
		code: '67 8b 33'
	}
	{
		asm: 'and [eax 0x54] ebx'
		code: '67 21 98 54 00 00 00'
	}
	{
		asm: 'lea ebx [rax 4 rbx 0x6b500e]'
		code: '8d 9c 98 0e 50 6b 00'
	}
	{
		asm: 'mov esi [ebx 2 eax]'
		code: '67 8b 34 43'
	}
	{
		asm: 'add rax [ebx 4 ecx 0x44]'
		code: '67 48 03 84 8b 44 00 00 00'
	}
	{
		asm: 'add [rbx 4 rcx 0x9876] ax'
		code: '66 01 84 8b 76 98 00 00'
	}
	{
		asm: 'call 0x1234'
		code: 'e8 34 12 00 00'
	}
	{
		asm: 'syscall'
		code: '0f 05'
	}
	{
		asm: 'ret'
		code: 'c3'
	}
	{
		asm: 'lea edi [ebx 8 eax 0x10]'
		code: '67 8d bc c3 10 00 00 00'
	}
]

each(Translations, tl => (
	asm := (type(tl.asm) :: {
		'string' -> tl.asm
		_ -> cat(tl.asm, Newline)
	})
	code := (type(tl.code) :: {
		'string' -> tl.code
		_ -> cat(tl.code, ' ')
	})

	text := assemble(asm).text
	t(replace(asm, Newline, ' / '), untransform(text), code)
))

(s.end)()

