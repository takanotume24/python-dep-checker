CABAL ?= cabal

.PHONY: build test lint format

build:
	$(CABAL) build all

test:
	$(CABAL) test

lint:
	$(CABAL) run structure-lint -- check --config structure-lint.json
	$(CABAL) run structure-lint -- positional --config structure-lint.json src
	$(CABAL) run structure-lint -- positional --config structure-lint.json app
	$(CABAL) run structure-lint -- positional --config structure-lint.json test

format:
	ormolu --mode inplace $$(find src app test -name '*.hs')
