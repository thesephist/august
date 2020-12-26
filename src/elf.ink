`` ELF file format library
`` c.f. https://man7.org/linux/man-pages/man5/elf.5.html

std := load('../vendor/std')
str := load('../vendor/str')

log := std.log
f := std.format
cat := std.cat
map := std.map

bytes := load('../lib/bytes')

padEndNull := bytes.padEndNull
toBytes := bytes.toBytes
zeroes := bytes.zeroes
transform := bytes.transform

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

ExecStartAddr := 4198400
ROStartAddr := 7032832

makeElf := (text, rodata) => (
	TextSection := {
		name: toBytes(0, 4)
		type: toBytes(1, 4) `` PROGBITS
		flags: toBytes(SectionFlag.Alloc | SectionFlag.ExecInstr, 8)
		addr: toBytes(ExecStartAddr, 8)
		offset: toBytes(4096, 8)
		align: toBytes(16, 8)
		body: text
	}
	RODataSection := {
		name: toBytes(6, 4)
		type: toBytes(1, 4) `` PROGBITS
		flags: toBytes(SectionFlag.Alloc, 8)
		addr: toBytes(ROStartAddr, 8)
		offset: toBytes(4096 + len(text), 8)
		align: toBytes(1, 8)
		body: rodata
	}
	StrTabSection := {
		name: toBytes(14, 4)
		type: toBytes(3, 4) `` STRTAB
		flags: zeroes(8)
		addr: zeroes(8)
		offset: toBytes(4096 + len(text) + len(rodata), 8)
		align: toBytes(1, 8)
		body: cat([
			'.text' + char(0)
			'.rodata' + char(0)
			'.shstrtab' + char(0)
		], '')
	}

	TextProg := {
		type: toBytes(ProgType.Load, 4)
		flags: toBytes(ProgFlag.Read | ProgFlag.Execute, 4)
		offset: toBytes(4096, 8)
		addr: toBytes(ExecStartAddr, 8)
		size: toBytes(len(text), 8)
	}
	RODataProg := {
		type: toBytes(ProgType.Load, 4)
		flags: toBytes(ProgFlag.Read | ProgFlag.Write, 4)
		offset: toBytes(4096, 8)
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
		toBytes(4096, 8) `` alignment
	], '')), '')

	` assemble sections and section metadata `

	Sections := [TextSection, RODataSection, StrTabSection]
	offsetSofar := [4096]
	SectionMetas := map(Sections, sec => (
		meta := {
			name: sec.name
			type: sec.type
			flags: sec.flags
			addr: sec.addr
			body: sec.body
			offset: toBytes(offsetSofar.0, 8)
			size: toBytes(len(sec.body), 8)
			link: zeroes(4)
			info: zeroes(4)
			align: sec.align
			entsize: zeroes(8)
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
		toBytes(4096 + len(SectionBodies), 8)

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
		toBytes(len(SectionMetas) - 1, 2)
	], '')

	` generate binary file `
	` NOTE: we pad out to page boundary for executable parts of the ELF.
		this assumption is baked into other offset calculations above. Grep for
		"4096" to find all of them. `
	elfFile := padEndNull(ElfHeader + ProgHeaders, 4096) +
		SectionBodies +
		SectionHeaders
)
