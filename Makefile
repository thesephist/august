all: run

# generate a dummy executable and run
run:
	./src/cli.ink; ./b.out; echo $$?

# run all tests under test/
check: run
	ink ./test/tests.ink
t: check

fmt:
	inkfmt fix src/*.ink
f: fmt

fmt-check:
	inkfmt src/*.ink
fk: fmt-check

