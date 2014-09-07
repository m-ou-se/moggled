sources = $(shell find ../source -name \*.d)

.PHONY: doc

doc: $(sources) $(wildcard *.ddoc)
	dmd -D -Dd. -o- $^
