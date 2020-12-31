all: run

# generate a dummy executable and run
run:
	./src/cli.ink ./test/asm/000.asm ./b.out; ./b.out; echo $$?

# run all tests under test/
check:
	ink ./src/test.ink
t: check

fmt:
	inkfmt fix src/*.ink
f: fmt

fmt-check:
	inkfmt src/*.ink
fk: fmt-check

