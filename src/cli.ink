#!/usr/bin/env ink

std := load('../vendor/std')
str := load('../vendor/str')

log := std.log
f := std.format
cat := std.cat
writeFile := std.writeFile

bytes := load('../lib/bytes')

transform := bytes.transform

elf := load('elf')
asm := load('asm')

makeElf := elf.makeElf

ElfPath := './b.out'

elfFile := makeElf(
	cat([
		transform('b8 01 00 00 00') `` mov eax, 0x1
		transform('bb 2a 00 00 00') `` mov ebx, 0x2a
		transform('cd 80') `` int 0x80
	], '')
	'Hello, World!' + char(10) + char(0)
)

` write binary to disk `
writeFile(ElfPath, elfFile, res => res :: {
	true -> exec('chmod', ['+x', ElfPath], '', evt => evt.type :: {
		'data' -> log('executable written.')
		_ -> log(f('file write error: {{message}}', evt))
	})
	_ -> log('Could not write executable to disk.')
})

