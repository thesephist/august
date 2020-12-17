#!/usr/bin/env ink

std := load('../vendor/std')
str := load('../vendor/str')

log := std.log
f := std.format
writeFile := std.writeFile

elf := load('elf')

elfFile := elf.elfFile

ElfPath := './b.out'

` write binary to disk `
writeFile(ElfPath, elfFile, res => res :: {
	true -> exec('chmod', ['+x', ElfPath], '', evt => evt.type :: {
		'data' -> log('executable written.')
		_ -> log(f('file write error: {{message}}', evt))
	})
	_ -> log('Could not write executable to disk.')
})

