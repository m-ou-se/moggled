sources = $(wildcard moggle/*.d moggle/*/*.d)

.PHONY: run-test

test: test.d $(sources)
	dmd -g -debug $^ -of$@

run-test: test
	./test

.PHONY: doc

doc: $(sources) $(wildcard doc/*.ddoc)
	dmd -D -Dddoc -o- $^
