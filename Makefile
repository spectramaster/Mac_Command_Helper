SHELL := /bin/bash

.PHONY: run install lint fmt ci test build docs release

VERSION_SH := mac-cmd-helper-v2.sh

run:
	@bash $(VERSION_SH)

install:
	@bash install-v2.sh -y

lint:
	@bash scripts/shellcheck.sh
	@markdownlint "**/*.md" --ignore node_modules || true

ci:
	@echo "Running CI tasks..."
	@bash scripts/shellcheck.sh
	@markdownlint "**/*.md" --ignore node_modules || true

docs:
	@echo "Docs index: INDEX.md"

release:
	@echo "Usage: make release version=2.1.0"
	@[ -n "$(version)" ] || (echo "Missing 'version' variable" && exit 1)
	@bash scripts/release.sh $(version)
