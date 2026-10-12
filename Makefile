# Wippy Framework
# Modules that have test directories with wippy.lock
TEST_MODULES = actor agent bootloader embeddings facade llm migration relay usage views
WIPPY ?= wippy
RUN_WIPPY = WIPPY="$(WIPPY)" bash scripts/run-wippy.sh

.PHONY: help check-manifests run-tests run-lint install test-runtime

help:
	@echo "Wippy Framework"
	@echo ""
	@echo "Usage:"
	@echo "  make run-tests      Run tests for all modules"
	@echo "  make run-lint       Run lint for all modules"
	@echo "  make check-manifests Validate package and test-app module types"
	@echo "  make install        Install dependencies for all test modules"
	@echo "  make test-runtime   Test real process and control delivery"

test-runtime:
	WIPPY_TEST_REQUIRE_CASES=1 $(RUN_WIPPY) src/actor/test test test -- actor_runtime_test
	WIPPY_TEST_REQUIRE_CASES=1 $(RUN_WIPPY) src/actor/test test test -- actor_runtime_resident_test
	WIPPY_TEST_REQUIRE_CASES=1 $(RUN_WIPPY) src/agent/test test \
		-o wippy.llm:process_host:default=wippy.terminal:host \
		-o wippy.llm:env_storage:default=app:env_storage test -- tools_controls_runtime_test
	WIPPY_TEST_REQUIRE_CASES=1 $(RUN_WIPPY) src/relay/test test \
		-o wippy.relay:application_host:default=app:processes \
		-o wippy.relay:user_security_scope:default=app:user test -- relay_runtime_test
	WIPPY_TEST_REQUIRE_CASES=1 $(RUN_WIPPY) test-harness/runner test test -- aggregate_checks_test

check-manifests:
	@python3 scripts/check_module_manifests.py

run-tests:
	@failed=0; \
	for mod in $(TEST_MODULES); do \
		printf "%-14s " "$$mod"; \
		if output=$$($(MAKE) -s -C src/$$mod/test test 2>&1); then \
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
		if output=$$($(MAKE) -s -C src/$$mod/test lint 2>&1); then \
			echo "PASSED"; \
		else \
			echo "FAILED"; \
			echo "$$output" | tail -5; \
			failed=1; \
		fi; \
	done; \
	if [ $$failed -eq 1 ]; then echo ""; echo "Lint errors found"; exit 1; fi; \
	echo ""; echo "All modules lint-clean"

install:
	@for mod in $(TEST_MODULES); do \
		echo "Installing $$mod..."; \
		(cd src/$$mod/test && wippy install 2>&1 | tail -1); \
	done

.PHONY: test-runner-go
test-runner-go:
	go -C test-harness/go test -race ./...
	go -C test-harness/go vet ./...
