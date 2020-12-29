` assembly instruction text -> binary encoder `

` Instruction database / reference:
	- http://ref.x86asm.net/coder64.html
	- https://x86.puri.sm/
	- http://www.cs.loyola.edu/~binkley/371/Encoding_Real_x86_Instructions.html
  x64 assembly reference:
	- http://cs.brown.edu/courses/cs033/docs/guides/x64_cheatsheet.pdf `

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
some := std.some
digit? := str.digit?
contains? := str.contains?
index := str.index
split := str.split
trimSuffix := str.trimSuffix
trim := str.trim
hasPrefix? := str.hasPrefix?
hasSuffix? := str.hasSuffix?

bytes := load('../lib/bytes')

toBytes := bytes.toBytes
transform := bytes.transform

Newline := char(10)
Tab := char(9)

number? := s => every(map(s, c => digit?(c) | c = '-'))
reg? := s => ~(type(s) = 'number')

instString := inst => cat(map(append([inst.name], inst.args), string), ' ')

` converts a register name to its bitstring representation `
encodeReg := reg => reg :: {
	` 4-byte registers `
	'eax' -> 0
	'ecx' -> 1
	'edx' -> 2
	'ebx' -> 3
	'esp' -> 4
	'ebp' -> 5
	'esi' -> 6
	'edi' -> 7
	` 8-byte registers `
	'rax' -> 0
	'rcx' -> 1
	'rdx' -> 2
	'rbx' -> 3
	'rsp' -> 4
	'rbp' -> 5
	'rsi' -> 6
	'rdi' -> 7
	` 2-byte registers `
	'ax' -> 0
	'cx' -> 1
	'dx' -> 2
	'bx' -> 3
	'sp' -> 4
	'bp' -> 5
	'si' -> 6
	'di' -> 7
	` byte registers `
	'al' -> 0
	'cl' -> 1
	'dl' -> 2
	'bl' -> 3
	'ah' -> 4
	'ch' -> 5
	'dh' -> 6
	'bh' -> 7

	() -> 0
	_ -> reg
}

` encodeRM encodes an R/M byte in an x86 instruction.
	At the moment, the mod bits are assumed to be register-only (11) and
	register names are passed to reg, rm. If an opcode extension is needed
	instead, pass the extension value as a number to reg, which will be written
	to the reg slot. `
encodeRM := (reg, rm) => (
	mod := xeh('c0')
	char(mod + encodeReg(reg) * 8 + encodeReg(rm))
)

failWith := msg => (log(msg), ())
encodeInst := inst => append([inst.name], inst.args) :: {
	['mov', _, _] -> map(inst.args, type) :: {
		['string', 'string'] -> transform('89') + encodeRM(inst.args.1, inst.args.0)
		['string', 'number'] -> char(xeh('b8') + encodeReg(inst.args.0)) + toBytes(inst.args.1, 4)
		_ -> failWith(f('Unsupported instruction: {{0}}', [instString(inst)]))
	}
	['inc', _] -> transform('ff') + encodeRM((), inst.args.0)
	['dec', _] -> transform('ff') + encodeRM(1, inst.args.0)
	['not', _] -> transform('f7') + encodeRM(2, inst.args.0)
	['neg', _] -> transform('f7') + encodeRM(3, inst.args.0)
	['add', _, _] -> map(inst.args, type) :: {
		['string', 'string'] -> transform('01') + encodeRM(inst.args.1, inst.args.0)
		['string', 'number'] -> transform('81') + encodeRM(0, inst.args.0) + toBytes(inst.args.1, 4)
		_ -> failWith(f('Unsupported instruction: {{0}}', [instString(inst)]))
	}
	['or', _, _] -> map(inst.args, type) :: {
		['string', 'string'] -> transform('09') + encodeRM(inst.args.1, inst.args.0)
		['string', 'number'] -> transform('81') + encodeRM(1, inst.args.0) + toBytes(inst.args.1, 4)
		_ -> failWith(f('Unsupported instruction: {{0}}', [instString(inst)]))
	}
	['and', _, _] -> map(inst.args, type) :: {
		['string', 'string'] -> transform('21') + encodeRM(inst.args.1, inst.args.0)
		['string', 'number'] -> transform('81') + encodeRM(4, inst.args.0) + toBytes(inst.args.1, 4)
		_ -> failWith(f('Unsupported instruction: {{0}}', [instString(inst)]))
	}
	['sub', _, _] -> map(inst.args, type) :: {
		['string', 'string'] -> transform('29') + encodeRM(inst.args.1, inst.args.0)
		['string', 'number'] -> transform('81') + encodeRM(5, inst.args.0) + toBytes(inst.args.1, 4)
		_ -> failWith(f('Unsupported instruction: {{0}}', [instString(inst)]))
	}
	['xor', _, _] -> map(inst.args, type) :: {
		['string', 'string'] -> transform('31') + encodeRM(inst.args.1, inst.args.0)
		['string', 'number'] -> transform('81') + encodeRM(6, inst.args.0) + toBytes(inst.args.1, 4)
		_ -> failWith(f('Unsupported instruction: {{0}}', [instString(inst)]))
	}
	['int', _] -> transform('cd') + char(inst.args.0)
	['syscall'] -> transform('0f 05')
	_ -> (
		log(f('Unknown instruction: {{0}}', [instString(inst)]))
		()
	)
}

assemble := prog => (
	lines := split(prog, Newline)

	` strip comments `
	lines := map(lines, s => contains?(s, ';') :: {
		true -> slice(s, 0, index(s, ';'))
		_ -> s
	})
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

	` generate machine code `
	mCode := map(insts, encodeInst)

	` emit generated code `
	some(map(mCode, x => x = ())) :: {
		false -> (
			Instructions := cat(mCode, '')
			ROData := ''

			[Instructions, ROData]
		)
		_ -> (
			log('Assembly error, exiting.')
			()
		)
	}
)

