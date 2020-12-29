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
- [ ] Support for read-only data
- [ ] Support for load/store from memory, lea instruction
- [ ] Support for named blocks and jumps (loops)
- [ ] Support for function calls and stack pop/push
- [ ] Support 64-bit syscall ABI
- [ ] Dynamic linking
- [ ] Compile from C subset
`

[args().2, args().3] :: {
	[(), _] -> log('usage: august <assembly.asm> <output>')
	_ -> (
		AsmPath := args().2
		ElfPath := args().3

		readFile(AsmPath, file => file :: {
			() -> log(f('Could not read asm: {{0}}', [0]))
			_ -> Assembly := assemble(file) :: {
				() -> ()
				_ -> (
					Instructions := Assembly.0
					ROData := Assembly.1

					` generate ELF file `
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
		})
	)
}

