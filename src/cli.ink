#!/usr/bin/env ink

std := load('../vendor/std')
str := load('../vendor/str')

log := std.log
f := std.format
cat := std.cat
readFile := std.readFile
writeFile := std.writeFile

elf := load('elf')
asm := load('asm')

makeElf := elf.makeElf
assemble := asm.assemble

`
TODO:
- [ ] Tests for asm.ink comparing assemble(code) = transform('xx xx xx ...')
- [ ] Symbol table for .text
- [ ] Dynamic linking
- [ ] Compile from C subset
`

AsmPath := args().2
ElfPath := args().3

[AsmPath, ElfPath] :: {
	[(), _] -> log('usage: august <assembly.asm> <output>')
	_ -> readFile(AsmPath, file => file :: {
		() -> log(f('Could not read asm: {{0}}', [0]))
		_ -> assembly := assemble(file) :: {
			() -> ()
			_ -> (
				` generate ELF file `
				elfFile := makeElf(assembly.text, assembly.rodata)

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
	})
}

