`` ELF file format library
`` c.f. https://man7.org/linux/man-pages/man5/elf.5.html

std := load('../vendor/std')
str := load('../vendor/str')

log := std.log
f := std.format
cat := std.cat
map := std.map

bytes := load('../lib/bytes')

toBytes := bytes.toBytes
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
		body: text
	}
	RODataSection := {
		name: toBytes(6, 4)
		type: toBytes(1, 4) `` PROGBITS
		flags: toBytes(SectionFlag.Alloc, 8)
		addr: toBytes(ROStartAddr, 8)
		offset: toBytes(4096 + 12, 8)
		body: rodata
	}
	StrTabSection := {
		name: toBytes(14, 4)
		type: toBytes(3, 4) `` STRTAB
		flags: toBytes(0, 8)
		addr: toBytes(0, 8)
		offset: toBytes(4096 + 12, 8)
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
		offset: toBytes(4096, 8) `` TODO: ELF segfaults with offset = 4K + len(text). Why?
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
		toBytes(16, 8)
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
			link: toBytes(0, 4)
			info: toBytes(0, 4)
			align: toBytes(16, 8)
			entsize: toBytes(0, 8)
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

	` assemble header `

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
		transform('01 00 00 00')

		`` execution start address (little-endian, 0x00401000 (default))
		toBytes(ExecStartAddr, 8)

		`` PROGRAM HEADER offset
		toBytes(ElfHeaderSize, 8)
		`` SECTION HEADER offset
		toBytes(4096 + len(SectionBodies), 8)

		`` padding (?)
		toBytes(0, 4)

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
	` NOTE: we pad out to page boundary for executable parts of the ELF `
	elfFile := ElfHeader +
		ProgHeaders +
		toBytes(0, 4096 - len(ElfHeader + ProgHeaders)) +
		SectionBodies +
		SectionHeaders
)
