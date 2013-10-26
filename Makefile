sources = $(wildcard moggle/*.d moggle/*/*.d)

.PHONY: run-test

run-test: test
	./test

test: test.d $(sources)
	dmd -debug $^ -of$@

