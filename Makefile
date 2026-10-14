# The Go implementation lives in go/; every target is run there.
# Run `make help` for the targets.

.DEFAULT_GOAL := build

# Keep the catch-all rule below from trying to remake this file.
Makefile: ;

%:
	@$(MAKE) -C go $@
