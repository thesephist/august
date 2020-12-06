# August 🪓

**August** is an assembler written in [Ink](https://dotink.co/). It currently aims to support assembling and statically linking ELF executables for ARM, RISC-V, and x86_64 architectures, though Mach-O support for ARM and x86_64 are possible. In the long term, August aims to be the compiler backend for a native, self-hosting Ink compiler toolchain based on [September](https://github.com/thesephist/september).

_August is ⚠️ under development ⚠️. Most parts of the system do not work at all yet._

## Design

August is an assembler and linker. The two halves are independent but designed to work together as a system. In both parts, August aims to be simple and spec-compliant wherever possible, perhaps at the cost of efficiency.

## Assembler

The August assembler is a pure function mapping an assembly program to a single ELF object file. It supports Intel-syntax assembly for x86 and takes after Nasm in syntax.

_more to come._

## ELF Linker

The August linker is a pure function mapping a set of (ELF, for now) object files into a single statically linked ELF executable.

_more to come._

## Progress to date

Currently, there is no distinction of the assembler and linker in August. `./src/cli.ink` emits a hard-coded minimal ELF binary constructed from pieces in the assembler. I'm still learning about the ELF format.

