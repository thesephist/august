`` ELF file format library
`` c.f. https://man7.org/linux/man-pages/man5/elf.5.html

std := load('../vendor/std')
str := load('../vendor/str')
quicksort := load('../vendor/quicksort')

log := std.log
f := std.format
cat := std.cat
map := std.map
append := std.append
sortBy := quicksort.sortBy

bytes := load('../lib/bytes')

padEndNull := bytes.padEndNull
toBytes := bytes.toBytes
zeroes := bytes.zeroes
transform := bytes.transform

SectionType := {
	Null: 0
	ProgBits: 1
	SymTab: 2
	StrTab: 3
	Rela: 4
	Hash: 5
	Dynamic: 6
	Note: 7
	NoBits: 8
	Rel: 9
	ShLib: 10
	DynSym: 11
}

SectionFlag := {
	Null: 0
	Write: 1
	Alloc: 2
	ExecInstr: 4
	MaskProc: 8
}

ProgType := {
	Null: 0
	Load: 1
	Dynamic: 2
	Interp: 4
	Note: 8
	ShLib: 16
	PHdr: 32
}

ProgFlag := {
	Execute: 1
	Write: 2
	Read: 4
}

SymTabInfo := {
	NoType: 0
	Object: 1
	Func: 2
	Section: 3
	File: 4
	Common: 5
	TLS: 6
	Local: 0
	Global: 1
	Weak: 2
}

SymTabOther := {
	Default: 0
	Internal: 1
	Hidden: 2
	Protected: 3
}

` system page size, assumed to be 4K, used for various padding sizes `
PageSize := 4096

` hard-coded virtual addresses for process address layout `
ExecStartAddr := 4198400
ROStartAddr := 7032832

` takes a map of symbols to their offsets in .text published by asm.assemble
	and returns a single chunk of data, the ELF64 symbol table. `
makeSymTab := (symbols, registerString) => (
	` the symbol table must be ordered by the address order `
	symbolAddrs := sortBy(map(keys(symbols), sym => {
		sym: sym
		addr: symbols.(sym)
	}), rec => rec.addr)

	` the first entry in the symtab must be a null entry `
	emptyEntry := {
		name: toBytes(0, 4)
		info: toBytes(SymTabInfo.NoType, 1)
		other: toBytes(SymTabOther.Default, 1)
		shndx: toBytes(0, 2)
		value: toBytes(0, 8)
		size: toBytes(0, 8)
	}
	entries := append([emptyEntry], map(symbolAddrs, rec => {
		name: toBytes(registerString(rec.sym), 4)
		info: toBytes(SymTabInfo.Func, 1)
		other: toBytes(SymTabOther.Default, 1)
		` symtab entries are for the .text section only, at section header index 1 `
		shndx: toBytes(1, 2)
		value: toBytes(ExecStartAddr + rec.addr, 8)
		size: toBytes(0, 8)
	}))

	cat(map(entries, ent => ent.name + ent.info + ent.other + ent.shndx + ent.value + ent.size), '')
)

` main ELF64-generating routine, takes output of asm.assemble and generates
	an ELF64 executable file `
makeElf := (text, symbols, rodata) => (
	` the ELF file contains a "string table" that is byte-indexed and contains
		section and symbol names in the binary. this is set up here, added to with
		registerString(), and compiled into the binary in the section .shstrtab `
	Strings := [char(0)]
	registerString := name => (
		idx := len(Strings.0)
		Strings.0 := Strings.0 + name + char(0)
		idx
	)

	` create a symbol table from a map of symbols to their values `
	symtab := makeSymTab(symbols, registerString)

	` .text must push .rodata to the next page `
	minTextPages := floor(len(text) / PageSize) + 1
	text := padEndNull(text, PageSize * minTextPages)

	` first section in the section header must be the null section `
	NullSection := {
		name: toBytes(0, 4)
		type: toBytes(SectionType.Null, 4)
		flags: zeroes(8)
		addr: zeroes(8)
		offset: zeroes(8)
		align: zeroes(8)
		body: ''
	}
	TextSection := {
		name: toBytes(registerString('.text'), 4)
		type: toBytes(SectionType.ProgBits, 4)
		flags: toBytes(SectionFlag.Alloc | SectionFlag.ExecInstr, 8)
		addr: toBytes(ExecStartAddr, 8)
		offset: toBytes(PageSize, 8)
		align: toBytes(16, 8)
		body: text
	}
	RODataSection := {
		name: toBytes(registerString('.rodata'), 4)
		type: toBytes(SectionType.ProgBits, 4)
		flags: toBytes(SectionFlag.Alloc, 8)
		addr: toBytes(ROStartAddr, 8)
		offset: toBytes(PageSize + len(text), 8)
		align: toBytes(1, 8)
		body: rodata
	}
	SymTabSection := {
		name: toBytes(registerString('.symtab'), 4)
		type: toBytes(SectionType.SymTab, 4)
		flags: zeroes(8)
		addr: zeroes(8)
		offset: toBytes(PageSize + len(text) + len(rodata), 8)
		align: toBytes(1, 8)
		body: symtab

		` specific to .symtab `
		link: toBytes(4, 4)
		` for now, all symbols are local, so index of first global symbol
			(sh_info) > total number of symbols + 1 (null symbol) `
		info: toBytes(len(symbols) + 1, 4)
		entsize: toBytes(24, 8)
	}
	StrTabSection := {
		name: toBytes(registerString('.shstrtab'), 4)
		type: toBytes(SectionType.StrTab, 4)
		flags: zeroes(8)
		addr: zeroes(8)
		offset: toBytes(PageSize + len(text) + len(rodata) + len(symtab), 8)
		align: toBytes(1, 8)
		body: Strings.0
	}

	TextProg := {
		type: toBytes(ProgType.Load, 4)
		flags: toBytes(ProgFlag.Read | ProgFlag.Execute, 4)
		offset: toBytes(PageSize, 8)
		addr: toBytes(ExecStartAddr, 8)
		size: toBytes(len(text), 8)
	}
	RODataProg := {
		type: toBytes(ProgType.Load, 4)
		flags: toBytes(ProgFlag.Read, 4)
		offset: toBytes(PageSize + len(text), 8)
		addr: toBytes(ROStartAddr, 8)
		size: toBytes(len(rodata), 8)
	}

	` below: auto-generated ELF metadata `

	` assemble program headers`

	Progs := [TextProg, RODataProg]
	ProgHeaders := cat(map([TextProg, RODataProg], prog => cat([
		prog.type
		prog.flags
		prog.offset
		prog.addr `` virtual
		prog.addr `` physical
		prog.size `` on file
		prog.size `` in mem
		toBytes(PageSize, 8) `` alignment
	], '')), '')

	` assemble sections and section metadata `

	Sections := [NullSection, TextSection, RODataSection, SymTabSection, StrTabSection]
	offsetSofar := [PageSize]
	SectionMetas := map(Sections, sec => (
		meta := {
			name: sec.name
			type: sec.type
			flags: sec.flags
			addr: sec.addr
			body: sec.body
			offset: toBytes(offsetSofar.0, 8)
			size: toBytes(len(sec.body), 8)
			link: sec.link :: {
				() -> zeroes(4)
				_ -> sec.link
			}
			info: sec.info :: {
				() -> zeroes(4)
				_ -> sec.info
			}
			align: sec.align
			entsize: sec.entsize :: {
				() -> zeroes(8)
				_ -> sec.entsize
			}
		}
		offsetSofar.0 := offsetSofar.0 + len(sec.body)
		meta
	))
	SectionBodies := cat(map(SectionMetas, sec => sec.body), '')
	SectionHeaders := cat(map(SectionMetas, sec => (
		cat([
			sec.name
			sec.type
			sec.flags
			sec.addr
			sec.offset
			sec.size
			sec.link
			sec.info
			sec.align
			sec.entsize
		], '')
	)), '')

	` assemble ELF header `

	ElfHeaderSize := 64
	ElfHeader := cat([
		`` ELF format specifier
		transform('7f') + 'ELF'
		`` format (64-bit two's complement, little-endian)
		transform('02 01')
		`` version, always 1
		transform('01 00 00 00')
		`` OS/ABI (System V) version 0
		transform('00 00 00 00 00 00')
		`` ELF type (executable)
		transform('02 00')
		`` Machine type (amd64)
		transform('3e 00')
		`` version, always 1
		toBytes(1, 4)

		`` execution start address (little-endian, 0x00401000 (default))
		toBytes(ExecStartAddr, 8)

		`` PROGRAM HEADER offset
		toBytes(ElfHeaderSize, 8)
		`` SECTION HEADER offset
		toBytes(PageSize + len(SectionBodies), 8)

		`` padding (?)
		zeroes(4)

		`` ELF HEADER size (0x40)
		toBytes(ElfHeaderSize, 2)

		`` PROGRAM HEADER individual size
		toBytes(56, 2)
		`` PROGRAM HEADER count
		toBytes(len(Progs), 2)

		`` SECTION HEADER individual size
		toBytes(64, 2)
		`` SECTION HEADER count
		toBytes(len(Sections), 2)

		`` SECTION TABLE index
		toBytes(len(Sections) - 1, 2)
	], '')

	` generate binary file `
	` NOTE: we pad out to page boundary for executable parts of the ELF.
		this assumption is baked into other offset calculations above. Grep for
		"PageSize" to find all of them. `
	elfFile := padEndNull(ElfHeader + ProgHeaders, PageSize) +
		SectionBodies +
		SectionHeaders
)
