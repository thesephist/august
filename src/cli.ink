#!/usr/bin/env ink

std := load('../vendor/std')
str := load('../vendor/str')

log := std.log
f := std.format
cat := std.cat
writeFile := std.writeFile

elf := load('elf')
asm := load('asm')

makeElf := elf.makeElf
assemble := asm.assemble

ElfPath := './b.out'

Instructions := assemble('
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
')

Instructions :: {
	() -> ()
	_ -> (
		ROData := 'Hello, World!' + char(10) + char(0)

		elfFile := makeElf(Instructions, ROData)

		` write binary to disk `
		writeFile(ElfPath, elfFile, res => res :: {
			true -> exec('chmod', ['+x', ElfPath], '', evt => evt.type :: {
				'data' -> log('executable written.')
				_ -> log(f('file write error: {{message}}', evt))
			})
			_ -> log('Could not write executable to disk.')
		})
	)
}

