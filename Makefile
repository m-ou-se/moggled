sources = $(wildcard */*.d */*/*.d)

test: tester
	@echo Running unit tests...
	@./tester && echo All tests passed, congratulations!

tester: $(sources)
	dmd -main -unittest $^ -of$@
