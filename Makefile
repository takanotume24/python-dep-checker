CABAL ?= cabal
DOCKER_IMAGE ?= python-dep-checker
DOCKER_RUN_ARGS ?=
ARGS ?= examples/script.py

.PHONY: build test lint format docker-build docker-run

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

docker-build:
	docker build -t $(DOCKER_IMAGE) .

docker-run: docker-build
	docker run --rm -v "$(CURDIR):/work" $(DOCKER_RUN_ARGS) $(DOCKER_IMAGE) $(ARGS)
