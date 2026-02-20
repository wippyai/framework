# Wippy Framework
# Modules with flat structure (wippy.yaml at package root)
PACKAGES_FLAT = migration embeddings facade views security docs terminal test

# Modules with src subfolder (wippy.yaml inside src/)
PACKAGES_SRC = actor agent bootloader llm relay usage

# Modules that have test directories with wippy.lock
TEST_MODULES = actor bootloader embeddings facade llm migration relay usage views

.PHONY: help run-tests run-lint install publish-all \
	publish-flat-% publish-src-%

help:
	@echo "Wippy Framework"
	@echo ""
	@echo "Usage:"
	@echo "  make run-tests      Run tests for all modules"
	@echo "  make run-lint       Run lint for all modules"
	@echo "  make install        Install dependencies for all test modules"
	@echo "  make publish-all    Publish all packages (skips unchanged)"

run-tests:
	@failed=0; \
	for mod in $(TEST_MODULES); do \
		printf "%-14s " "$$mod"; \
		output=$$(cd src/$$mod/test && wippy run test 2>&1); \
		if echo "$$output" | grep -q "PASSED"; then \
			echo "PASSED"; \
		else \
			echo "FAILED"; \
			echo "$$output" | tail -5; \
			failed=1; \
		fi; \
	done; \
	if [ $$failed -eq 1 ]; then echo ""; echo "Some tests failed"; exit 1; fi; \
	echo ""; echo "All tests passed"

run-lint:
	@failed=0; \
	for mod in $(TEST_MODULES); do \
		printf "%-14s " "$$mod"; \
		output=$$(cd src/$$mod/test && wippy lint 2>&1); \
		if echo "$$output" | grep -q "errors"; then \
			echo "$$output" | grep -oP 'Checked.*'; \
			failed=1; \
		else \
			echo "$$output" | grep -oP 'Checked.*'; \
		fi; \
	done; \
	if [ $$failed -eq 1 ]; then echo ""; echo "Lint errors found"; exit 1; fi; \
	echo ""; echo "All modules lint-clean"

install:
	@for mod in $(TEST_MODULES); do \
		echo "Installing $$mod..."; \
		(cd src/$$mod/test && wippy install 2>&1 | tail -1); \
	done

publish-all:
	@for pkg in $(PACKAGES_FLAT); do \
		echo "Publishing $$pkg..."; \
		cd src/$$pkg && wippy publish || echo "$$pkg unchanged or failed"; \
		cd ../..; \
	done
	@for pkg in $(PACKAGES_SRC); do \
		echo "Publishing $$pkg..."; \
		cd src/$$pkg/src && wippy publish || echo "$$pkg unchanged or failed"; \
		cd ../../..; \
	done
	@echo "All packages processed"
