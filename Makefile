# Wippy Framework
# Modules that have test directories with wippy.lock
TEST_MODULES = actor agent bootloader embeddings facade llm migration relay usage views
WIPPY ?= wippy
BENCH_OUTPUT_DIR ?= /tmp/wippy-framework-benchmarks
BENCH_WARMUP ?= 100
BENCH_SAMPLES ?= 100
BENCH_SIZES ?= 1 8 32
BENCH_MEMORY_OPERATIONS ?= 10000
BENCH_EXACT_ALLOCATIONS ?= 1
BENCH_REVISION ?= $(shell git rev-parse HEAD)
BENCH_PROFILER_FLAG = $(if $(filter 1,$(BENCH_EXACT_ALLOCATIONS)),--profiler)
RUN_WIPPY = WIPPY="$(WIPPY)" bash scripts/run-wippy.sh

.PHONY: help check-manifests run-tests run-lint install test-runtime bench

help:
	@echo "Wippy Framework"
	@echo ""
	@echo "Usage:"
	@echo "  make run-tests      Run tests for all modules"
	@echo "  make run-lint       Run lint for all modules"
	@echo "  make check-manifests Validate package and test-app module types"
	@echo "  make install        Install dependencies for all test modules"
	@echo "  make test-runtime   Test real process and control delivery"
	@echo "  make bench          Write Lua operation benchmarks outside the repository"

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

bench:
	@set -eu; \
	output="$(abspath $(BENCH_OUTPUT_DIR))"; \
	mkdir -p "$$output"; \
	output=$$(cd "$$output" && pwd -P); \
	repo=$$(pwd -P); \
	case "$$output/" in "$$repo/"*) echo 'Benchmark output must be outside the repository' >&2; exit 1;; esac; \
	export WIPPY_BENCH_WARMUP="$(BENCH_WARMUP)" WIPPY_BENCH_SAMPLES="$(BENCH_SAMPLES)"; \
	export WIPPY_BENCH_MEMORY_OPERATIONS="$(BENCH_MEMORY_OPERATIONS)"; \
	export WIPPY_BENCH_EXACT_ALLOCATIONS="$(BENCH_EXACT_ALLOCATIONS)"; \
	export WIPPY_TEST_REQUIRE_CASES=1; \
	export WIPPY_BENCH_REVISION="$(BENCH_REVISION)"; \
	WIPPY_BENCH_RUNTIME=$$("$(WIPPY)" version); export WIPPY_BENCH_RUNTIME; \
	for size in $(BENCH_SIZES); do \
		export WIPPY_BENCH_SIZE="$$size"; \
		for name in actor_roundtrip actor_lifecycle actor_resident tools_sequential tools_parallel relay_roundtrip relay_pipeline; do \
			rm -f "$$output/$$name-$$size.json"; \
		done; \
		$(RUN_WIPPY) src/actor/test test -c $(BENCH_PROFILER_FLAG) \
			-o "wippy.test:benchmark_output:directory=$$output" test -- actor_runtime_benchmark; \
		$(RUN_WIPPY) src/actor/test test -c $(BENCH_PROFILER_FLAG) \
			-o "wippy.test:benchmark_output:directory=$$output" test -- actor_lifecycle_benchmark; \
		$(RUN_WIPPY) src/actor/test test -c $(BENCH_PROFILER_FLAG) \
			-o "wippy.test:benchmark_output:directory=$$output" test -- actor_resident_benchmark; \
		$(RUN_WIPPY) src/agent/test test -c $(BENCH_PROFILER_FLAG) \
			-o "wippy.test:benchmark_output:directory=$$output" \
			-o wippy.llm:process_host:default=wippy.terminal:host \
			-o wippy.llm:env_storage:default=app:env_storage test -- tools_controls_benchmark; \
		$(RUN_WIPPY) src/relay/test test -c $(BENCH_PROFILER_FLAG) \
			-o "wippy.test:benchmark_output:directory=$$output" \
			-o wippy.relay:application_host:default=app:processes \
			-o wippy.relay:user_security_scope:default=app:user test -- relay_runtime_benchmark; \
		$(RUN_WIPPY) src/relay/test test -c $(BENCH_PROFILER_FLAG) \
			-o "wippy.test:benchmark_output:directory=$$output" \
			-o wippy.relay:application_host:default=app:processes \
			-o wippy.relay:user_security_scope:default=app:user test -- relay_pipeline_benchmark; \
		for name in actor_roundtrip actor_lifecycle actor_resident tools_sequential tools_parallel relay_roundtrip relay_pipeline; do \
			test -s "$$output/$$name-$$size.json"; \
		done; \
	done

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
