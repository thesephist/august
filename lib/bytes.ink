` byte-level byte string manipulation functions `

std := load('../vendor/std')
str := load('../vendor/str')

xeh := std.xeh
cat := std.cat
map := std.map
split := str.split

Null := char(0)

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

