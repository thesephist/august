#!/bin/sh

nasm -f elf64 test/001.s
ld -s test/001.o

./a.out
echo $?

