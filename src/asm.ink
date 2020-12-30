` assembly instruction text -> binary encoder `

` Instruction database / reference:
	- http://ref.x86asm.net/coder64.html
	- https://x86.puri.sm/
	- http://www.cs.loyola.edu/~binkley/371/Encoding_Real_x86_Instructions.html
  x64 assembly reference:
	- http://cs.brown.edu/courses/cs033/docs/guides/x64_cheatsheet.pdf `

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
reduce := std.reduce
filter := std.filter
every := std.every
some := std.some

digit? := str.digit?
contains? := str.contains?
index := str.index
split := str.split
replace := str.replace
trimPrefix := str.trimPrefix
trimSuffix := str.trimSuffix
trim := str.trim
hasPrefix? := str.hasPrefix?
hasSuffix? := str.hasSuffix?

bytes := load('../lib/bytes')

toBytes := bytes.toBytes
transform := bytes.transform

elf := load('elf')

ROStartAddr := elf.ROStartAddr

Newline := char(10)
Tab := char(9)

number? := s => every(map(s, c => digit?(c) | c = '-'))
failWith := msg => (log(msg), ())

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

	` if immediate, just return the immediate `
	_ -> reg
}

InstAliases := {
	jz: 'je'
	jnz: 'jne'
	jnle: 'jg'
	jnge: 'jl'
	jnl: 'jge'
	jng: 'jle'
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

encodeInst := (inst, offset, labels, symbols, addReloc) => (
	` normalize instruction aliases `
	instName := (InstAliases.(inst.name) :: {
		() -> inst.name
		_ -> InstAliases.(inst.name)
	})

	` map any potential labels in arguments to their correct values `
	args := map(inst.args, arg => [labels.(arg), symbols.(arg)] :: {
		[(), ()] -> arg
		[_, ()] -> labels.(arg)
		_ -> (
			` certain jump instructions store labels at offset 2 `
			byteOffset := (instName :: {
				'jmp' -> 1
				'je' -> 2
				'jne' -> 2
				'jl' -> 2
				'jge' -> 2
				'jle' -> 2
				'jg' -> 2
				'mov' -> 1
				` assume all other ALU instructions take the form:
					primary opcode + r/m byte + immediate `
				_ -> 2
			})
			addReloc(arg, offset, byteOffset)
			symbols.(arg)
		)
	})

	` emit correctly encoded instruction `
	append([instName], args) :: {
		['mov', _, _] -> map(args, type) :: {
			['string', 'string'] -> transform('89') + encodeRM(args.1, args.0)
			['string', 'number'] -> char(xeh('b8') + encodeReg(args.0)) + toBytes(args.1, 4)
			_ -> failWith(f('Unsupported instruction: {{0}}', [instString(inst)]))
		}
		['push', _] -> type(args.0) :: {
			'string' -> char(xeh('50') + encodeReg(args.0))
			'number' -> transform('68') + toBytes(args.0, 4)
			_ -> failWith(f('Unsupported instruction: {{0}}', [instString(inst)]))
		}
		['pop', _] -> type(args.0) :: {
			'string' -> transform('8f') + encodeRM(0, args.0)
			_ -> failWith(f('Unsupported instruction: {{0}}', [instString(inst)]))
		}
		['inc', _] -> transform('ff') + encodeRM((), args.0)
		['dec', _] -> transform('ff') + encodeRM(1, args.0)
		['not', _] -> transform('f7') + encodeRM(2, args.0)
		['neg', _] -> transform('f7') + encodeRM(3, args.0)
		['add', _, _] -> map(args, type) :: {
			['string', 'string'] -> transform('01') + encodeRM(args.1, args.0)
			['string', 'number'] -> transform('81') + encodeRM(0, args.0) + toBytes(args.1, 4)
			_ -> failWith(f('Unsupported instruction: {{0}}', [instString(inst)]))
		}
		['or', _, _] -> map(args, type) :: {
			['string', 'string'] -> transform('09') + encodeRM(args.1, args.0)
			['string', 'number'] -> transform('81') + encodeRM(1, args.0) + toBytes(args.1, 4)
			_ -> failWith(f('Unsupported instruction: {{0}}', [instString(inst)]))
		}
		['and', _, _] -> map(args, type) :: {
			['string', 'string'] -> transform('21') + encodeRM(args.1, args.0)
			['string', 'number'] -> transform('81') + encodeRM(4, args.0) + toBytes(args.1, 4)
			_ -> failWith(f('Unsupported instruction: {{0}}', [instString(inst)]))
		}
		['sub', _, _] -> map(args, type) :: {
			['string', 'string'] -> transform('29') + encodeRM(args.1, args.0)
			['string', 'number'] -> transform('81') + encodeRM(5, args.0) + toBytes(args.1, 4)
			_ -> failWith(f('Unsupported instruction: {{0}}', [instString(inst)]))
		}
		['xor', _, _] -> map(args, type) :: {
			['string', 'string'] -> transform('31') + encodeRM(args.1, args.0)
			['string', 'number'] -> transform('81') + encodeRM(6, args.0) + toBytes(args.1, 4)
			_ -> failWith(f('Unsupported instruction: {{0}}', [instString(inst)]))
		}
		['cmp', _, _] -> map(args, type) :: {
			['string', 'string'] -> transform('39') + encodeRM(args.1, args.0)
			['string', 'number'] -> transform('81') + encodeRM(7, args.0) + toBytes(args.1, 4)
			_ -> failWith(f('Unsupported instruction: {{0}}', [instString(inst)]))
		}
		['jmp', _] -> transform('e9') + toBytes(args.0, 4)
		['je', _] -> transform('0f 84') + toBytes(args.0, 4)
		['jne', _] -> transform('0f 85') + toBytes(args.0, 4)
		['jl', _] -> transform('0f 8c') + toBytes(args.0, 4)
		['jge', _] -> transform('0f 8c') + toBytes(args.0, 4)
		['jle', _] -> transform('0f 8d') + toBytes(args.0, 4)
		['jg', _] -> transform('0f 8e') + toBytes(args.0, 4)
		['int', _] -> transform('cd') + char(args.0)
		['syscall'] -> transform('0f 05')
		['ret'] -> transform('c3')
		_ -> failWith(f('Unknown instruction: {{0}}', [instString(inst)]))
	}
)

` main assembly encoder function, text code => machine code byte string `
assemble := prog => (
	lines := split(prog, Newline)

	` strip comments `
	lines := map(lines, s => contains?(s, ';') :: {
		true -> slice(s, 0, index(s, ';'))
		_ -> s
	})
	lines := map(lines, s => trim(trim(s, ' '), Tab))
	lines := filter(lines, s => len(s) > 0)

	` parse out section directives for .text / .rodata, which are the two supported `
	sections := reduce(lines, (acc, line) => line :: {
		'section .text' -> acc.cur := 'text'
		'section .rodata' -> acc.cur := 'rodata'
		_ -> hasPrefix?(line, 'section') :: {
			true -> failWith(f('Unrecognized section: {{0}}', line))
			_ -> (
				curSec := acc.(acc.cur)
				curSec.len(curSec) := line

				acc
			)
		}
	}, {cur: 'text', text: [], rodata: []})

	` parse and generate rodata section data segments `
	parseQuotedLine := line => (sub := (parsed, token, inQuote?, i) => line.(i) :: {
		() -> filter(token :: {
			'' -> parsed
			_ -> parsed.len(parsed) := token
		}, s => len(s) > 0)
		'\\' -> inQuote? :: {
			true -> sub(parsed, token + line.(i + 1), inQuote?, i + 2)
			_ -> sub(parsed, token + line.(i), inQuote?, i + 1)
		}
		'"' -> inQuote? :: {
			true -> sub(parsed.len(parsed) := token, '', ~inQuote?, i + 1)
			_ -> sub(parsed.len(parsed) := token, '', ~inQuote?, i + 1)
		}
		' ' -> inQuote? :: {
			true -> sub(parsed, token + line.(i), inQuote?, i + 1)
			_ -> sub(parsed.len(parsed) := token, '', inQuote?, i + 1)
		}
		_ -> sub(parsed, token + line.(i), inQuote?, i + 1)
	})([], '', false, 0)
	decodeData := s => (
		pcs := parseQuotedLine(s)
		chunks := map(pcs, pc => [hasPrefix?(pc, '0x'), number?(pc)] :: {
			[true, _] -> char(xeh(slice(pc, 2, len(pc))))
			[_, true] -> char(number(pc))
			_ -> replace(pc, '\\"', '"')
		})
		chunks :: {
			() -> ()
			_ -> cat(chunks, '')
		}
	)
	segments := reduce(sections.rodata, (acc, line) => hasSuffix?(line, ':') :: {
		true -> acc.cur := trimSuffix(line, ':')
		_ -> split(line, ' ').0 :: {
			'db' -> (
				` mark offset into rodata section `
				info := trimPrefix(line, 'db ')
				acc.labels.(acc.cur) := ROStartAddr + len(acc.data)
				acc.data := acc.data + decodeData(info)
				acc
			)
			'eq' -> (
				info := trimPrefix(line, 'eq ')
				number?(info) :: {
					true -> (
						acc.labels.(acc.cur) := number(info)
						acc
					)
					_ -> failWith('Could not decode data segment line: {{0}}', [line])
				}
			)
			_ -> failWith(f('Could not decode data segment line: {{0}}', [line]))
		}
	}, {cur: (), labels: {}, data: ''})

	` parse and translate text code into instruction seq `
	symbols := {} `` symbol -> instruction offset
	insts := map(sections.text, (line, i) => (
		` instruction offset is line offset - # symbol labels `
		offset := i - len(symbols)
		pcs := map(split(line, ' '), s => trimSuffix(s, ','))

		len(pcs) = 1 & hasSuffix?(pcs.0, ':') :: {
			true -> (
				symbol := trimSuffix(pcs.0, ':')
				symbols.(symbol) := offset
				()
			)
			_ -> (
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
			)
		}
	))
	insts := filter(insts, inst => ~(inst = ()))

	` set up relocation list (symbol table) for machine code generation `
	relocations := []
	addRelocation := (name, instOffset, byteOffset) => relocations.len(relocations) := {
		name: name
		instOffset: instOffset
		byteOffset: byteOffset
	}

	` generate machine code `
	mCode := map(insts, (inst, i) => encodeInst(inst, i, segments.labels, symbols, addRelocation))
	every(map(mCode, code => ~(code = ()))) :: {
		false -> ()
		_ -> (
			cumulativeCodeOffsets := reduce(mCode, (cum, code) => (
				last := cum.(len(cum) - 1)
				cur := last + len(code)
				cum.len(cum) := cur
			), [0])

			` compute machine code address (vaddr) offsets for each label `
			symbolAddrs := {}
			each(
				keys(symbols)
				symbol => symbolAddrs.(symbol) := cumulativeCodeOffsets.(symbols.(symbol))
			)

			` perform local relocations `
			each(relocations, rlc => (
				inst := mCode.(rlc.instOffset)
				relAddr := symbolAddrs.(rlc.name) - cumulativeCodeOffsets.(rlc.instOffset + 1)
				mCode.(rlc.instOffset) := (
					` assume for now that relocated addresses are relative & 32-bit `
					inst.(rlc.byteOffset) := toBytes(relAddr, 4)
				)
			))

			` emit generated code `
			some(map(mCode, x => x = ())) :: {
				false -> {
					text: cat(mCode, '')
					rodata: segments.data
				}
				_ -> failWith('Assembly error, exiting.')
			}
		)
	}
)

