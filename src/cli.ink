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
	mov eax 0x1
	mov ebx 42
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

