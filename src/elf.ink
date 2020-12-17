`` ELF file format library

std := load('../vendor/std')
str := load('../vendor/str')

log := std.log
f := std.format
xeh := std.xeh
cat := std.cat
map := std.map
split := str.split

Null := char(0)
ExecStartAddr := 4198400

` 64-bit word of zeroes `
ZWord := '00 00 00 00 00 00 00 00'
ZQWord := cat([ZWord, ZWord, ZWord, ZWord], ' ')

` pad end of string with null bytes `
padEndNull := (s, size) => len(s) < size :: {
	true -> padEndNull(s + Null, size)
	_ -> s
}

` takes a number, formats it to a little-endian byte string of given min width
	.e.g. 511 => '\xff \x01'`
toBytes := (n, minBytes) => (sub := (acc, n) => (
	acc := acc + char(n % 256)
	rest := floor(n / 256) :: {
		0 -> padEndNull(acc, minBytes)
		_ -> sub(acc, rest)
	}
))('', n)

` 'xx xx xx xx' -> byte string `
transform := hexs => cat(map(split(hexs, ' '), code => char(xeh(code))), '')

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
	`` sizeof == word size
	toBytes(ExecStartAddr, 8)

	`` PROGRAM HEADER offset (0x40)
	`` sizeof == word size
	toBytes(64, 8)
	`` SECTION HEADER offset (0x1020)
	`` sizeof == word size
	toBytes(4128, 8)

	`` padding (?)
	toBytes(0, 4)

	`` ELF HEADER size (0x40)
	toBytes(64, 2)

	`` PROGRAM HEADER individual size
	toBytes(56, 2)
	`` PROGRAM HEADER count
	toBytes(2, 2)

	`` SECTION HEADER individual size
	toBytes(64, 2)
	`` SECTION HEADER count
	toBytes(3, 2)

	`` SECTION TABLE index
	toBytes(2, 2)
], '')

ElfBody := cat([
	`` PROGRAM HEADER TABLE

	`` PROG: ??
	transform('01 00 00 00 04 00 00 00') `` type: LOAD
	transform('00 00 00 00 00 00 00 00') `` offset: 0
	transform('00 00 40 00 00 00 00 00') `` virt addr 0x400000
	transform('00 00 40 00 00 00 00 00') `` phys addr 0x400000
	transform('b0 00 00 00 00 00 00 00') `` size on file: 0xb0
	transform('b0 00 00 00 00 00 00 00') `` size in mem: 0xb0
	transform('00 10 00 00 00 00 00 00') `` flags: Read / align: 0x10

	`` PROG: .text
	transform('01 00 00 00 05 00 00 00') `` type: LOAD
	transform('00 10 00 00 00 00 00 00') `` offset: 0
	transform('00 10 40 00 00 00 00 00') `` virt addr 0x401000
	transform('00 10 40 00 00 00 00 00') `` phys addr 0x401000
	transform('0c 00 00 00 00 00 00 00') `` size on file: 0x0c
	transform('0c 00 00 00 00 00 00 00') `` size in mem: 0x0c
	transform('00 10 00 00 00 00 00 00') `` flags: Read, Execute / align: 0x10

	`` PADDING
	toBytes(0, 2048)
	toBytes(0, 1024)
	toBytes(0, 512)
	toBytes(0, 256)
	toBytes(0, 80)
], '')

Sections := cat([
	`` PROGRAM TEXT START
	transform('b8 01 00 00 00') `` mov eax, 0x1
	transform('bb 2a 00 00 00') `` mov ebx, 0x2a
	transform('cd 80') `` int 0x80

	`` SECTION: .shstrtab
	Null `` SHT_NULL
	'.shstrtab'
	'.text'
	toBytes(0, 4) `` padding
], '')

SectionHeaders := cat([
	`` SECTION HEADER TABLE

	`` SECTION SHT_NULL
	toBytes(0, 64)

	`` SECTION  .text
	transform('0b 00 00 00 01 00 00 00') `` ??
	toBytes(6, 8) `` type: PROGBITS
	toBytes(ExecStartAddr, 8) `` address
	toBytes(256, 8) `` offset
	toBytes(12, 8) `` size
	toBytes(0, 4) `` entsize
	transform('10 00 00 00 00 00 00 00') `` flags, link, info
	toBytes(0, 4) `` alignment?

	`` SECTION .shstrtab
	transform('01 00 00 00 03 00 00 00') `` ??
	toBytes(0, 4) `` type: STRTAB
	toBytes(0, 8) `` address
	toBytes(4108, 8) `` offset
	toBytes(11, 8) `` size
	toBytes(0, 8) `` entsize
	transform('01 00 00 00 00 00 00 00') `` flags, link, info
	toBytes(0, 4) `` alignment?
], '')

` generate binary file `
elfFile := ElfHeader + ElfBody + Sections + SectionHeaders

