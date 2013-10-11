sources = $(wildcard */*.d */*/*.d)

test: tester
	./tester

tester: $(sources)
	dmd -main -unittest $^ -of$@
