#!/usr/bin/env ink

std := load('../vendor/std')
str := load('../vendor/str')

log := std.log
f := std.format
xeh := std.xeh
cat := std.cat
map := std.map
writeFile := std.writeFile
split := str.split

` 64-bit word of zeroes `
ZWord := '00 00 00 00 00 00 00 00'
ZQWord := cat([ZWord, ZWord, ZWord, ZWord], ' ')

ElfPath := './b.out'
ElfHeader := cat([
	`` ELF format specifier
	'7f 45 4c 46'
	`` format (64-bit two's complement, little-endian)
	'02 01'
	`` version, always 1
	'01 00 00 00'
	`` OS/ABI (System V) version 0
	'00 00 00 00 00 00'
	`` ELF type (executable)
	'02 00'
	`` Machine type (amd64)
	'3e 00'
	`` version, always 1
	'01 00 00 00'

	`` execution start address (little-endian, 0x00401000 (default))
	`` sizeof == word size
	'00 10 40 00 00 00 00 00'

	`` PROGRAM HEADER offset (0x40)
	`` sizeof == word size
	'40 00 00 00 00 00 00 00'
	`` SECTION HEADER offset (0x1020)
	`` sizeof == word size
	'20 10 00 00 00 00 00 00'

	`` padding (?)
	'00 00 00 00'

	`` ELF HEADER size (0x40)
	'40 00'

	`` PROGRAM HEADER individual size
	'38 00'
	`` PROGRAM HEADER count
	'02 00'

	`` SECTION HEADER individual size
	'40 00'
	`` SECTION HEADER count

	'03 00'
	`` SECTION TABLE index
	'02 00'
], ' ')
ElfContent := cat([
	`` ELF HEADER
	ElfHeader

	`` PROGRAM HEADER TABLE

	`` PROG: ??
	'01 00 00 00 04 00 00 00' `` type: LOAD
	'00 00 00 00 00 00 00 00' `` offset: 0
	'00 00 40 00 00 00 00 00' `` virt addr 0x400000
	'00 00 40 00 00 00 00 00' `` phys addr 0x400000
	'b0 00 00 00 00 00 00 00' `` size on file: 0xb0
	'b0 00 00 00 00 00 00 00' `` size in mem: 0xb0
	'00 10 00 00 00 00 00 00' `` flags: Read / align: 0x10

	`` PROG: .text
	'01 00 00 00 05 00 00 00' `` type: LOAD
	'00 10 00 00 00 00 00 00' `` offset: 0
	'00 10 40 00 00 00 00 00' `` virt addr 0x401000
	'00 10 40 00 00 00 00 00' `` phys addr 0x401000
	'0c 00 00 00 00 00 00 00' `` size on file: 0x0c
	'0c 00 00 00 00 00 00 00' `` size in mem: 0x0c
	'00 10 00 00 00 00 00 00' `` flags: Read, Execute / align: 0x10

	`` PADDING
	ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord
	ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord
	ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord
	ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord
	ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord
	ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord
	ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord
	ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord
	ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord
	ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord
	ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord
	ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord
	ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord
	ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord
	ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord, ZQWord
	ZQWord, ZQWord
	ZWord, ZWord

	`` PROGRAM TEXT START
	'b8 01 00 00 00' `` mov eax, 0x1
	'bb 2a 00 00 00' `` mov ebx, 0x2a
	'cd 80' `` int 0x80

	`` SECTION: .shstrtab
	'00' `` SHT_NULL
	'2e 73 68 73 74 72 74 61 62 00' `` .shstrtab.
	'2e 74 65 78 74' `` .text
	'00 00 00 00' `` padding

	`` SECTION HEADER TABLE

	`` SECTION SHT_NULL
	ZQWord, ZQWord

	`` SECTION  .text
	'0b 00 00 00 01 00 00 00' `` ??
	'06 00 00 00 00 00 00 00' `` Type: PROGBITS
	'00 10 40 00 00 00 00 00' `` address
	'00 10 00 00 00 00 00 00' `` offset
	'0c 00 00 00 00 00 00 00' `` size
	ZWord `` entsize
	'10 00 00 00 00 00 00 00' `` flags, link, info
	ZWord `` alignment?

	`` SECTION .shstrtab
	'01 00 00 00 03 00 00 00' `` ??
	ZWord `` STRTAB
	'00 00 00 00 00 00 00 00' `` address
	'0c 10 00 00 00 00 00 00' `` offset
	'11 00 00 00 00 00 00 00' `` size
	'00 00 00 00 00 00 00 00' `` entsize
	'01 00 00 00 00 00 00 00' `` flags, link, info
	ZWord `` alignment?
], ' ')

` generate binary file `
elfFile := cat(map(split(ElfContent, ' '), code => char(xeh(code))), '')

` write binary to disk `
writeFile(ElfPath, elfFile, res => res :: {
	true -> exec('chmod', ['+x', ElfPath], '', evt => evt.type :: {
		'data' -> log('executable written.')
		_ -> log(f('file write error: {{message}}', evt))
	})
	_ -> log('Could not write executable to disk.')
})

