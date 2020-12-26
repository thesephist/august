` assembly instruction text -> binary encoder `

` Instruction database / reference:
	- http://ref.x86asm.net/coder64.html
	- https://x86.puri.sm/ `

asm := load('asm')

std := load('../vendor/std')
str := load('../vendor/str')

log := std.log
f := std.format
xeh := std.xeh
cat := std.cat
slice := std.slice
append := std.append
map := std.map
each := std.each
filter := std.filter
every := std.every
digit? := str.digit?
split := str.split
trimSuffix := str.trimSuffix
trim := str.trim
hasPrefix? := str.hasPrefix?

bytes := load('../lib/bytes')

transform := bytes.transform

Newline := char(10)
Tab := char(9)

number? := s => every(map(s, digit?))
reg? := s => ~(type(s) = 'number')

` converts a register name to its bitstring representation `
encodeReg := reg => reg :: {
	'eax' -> 0
	'ebx' -> 3
	_ -> ~1
}

encodeInst := inst => append([inst.name], inst.args) :: {
	['mov', _, _] -> (
		dst := inst.args.0
		src := inst.args.1

		` TODO: only supports immediates -> registers for now `
		char(xeh('b8') + encodeReg(dst)) + char(src) + transform('00 00 00')
	)
	['int', _] -> transform('cd') + char(inst.args.0)
	_ -> (
		log(f('Unknown instruction name {{name}}', inst))
		()
	)
}

assemble := prog => (
	lines := split(prog, Newline)
	lines := map(lines, s => trim(trim(s, ' '), Tab))
	lines := filter(lines, s => len(s) > 0)

	` parse and translate text code into instruction seq `
	insts := map(lines, line => (
		pcs := map(split(line, ' '), s => trimSuffix(s, ','))
		pcs := map(pcs, pc => hasPrefix?(pc, '0x') :: {
			true -> xeh(slice(pc, 2, len(pc)))
			_ -> number?(pc) :: {
				true -> number(pc)
				false -> pc
			}
		})
		{
			name: pcs.0
			args: slice(pcs, 1, len(pcs))
		}
	))

	`` TODO: debug
	`` each(insts, inst => log(f('{{name}} -> {{args}}', inst)))

	` generate machine code `
	mCode := map(insts, encodeInst)

	` emit generated code `
	every(map(mCode, x => x = ())) :: {
		false -> cat(mCode, '')
		_ -> (
			log('Assembly error, exiting.')
			()
		)
	}
)

