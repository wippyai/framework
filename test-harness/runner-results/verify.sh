#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
wippy_bin="${WIPPY_BIN:-wippy}"

while IFS='|' read -r scenario expected; do
  set +e
  output=$("$wippy_bin" test --config .wippy.yaml test -- "app:$scenario" 2>&1)
  status=$?
  set -e
  if [ "$status" -ne 1 ] || ! grep -Fq 'FAILED' <<< "$output" ||
     ! grep -Fq "$expected" <<< "$output"; then
    printf 'runner accepted or misreported %s (exit %s):\n%s\n' "$scenario" "$status" "$output"
    exit 1
  fi
done <<'SCENARIOS'
returns_false|test returned false
raises_error|expected execution failure
error_status|test returned false
planned_error_status|test returned false
replaced_plan|test process reported more than one plan
completion_without_plan|test process did not report a plan
missing_completion|test process did not report completion
conflicting_completion|test completion counts disagree
empty_completion|test completion counts disagree
failing_case|expected case failure
SCENARIOS

for scenario in returns_true returns_nil skipped_case; do
  if ! output=$("$wippy_bin" test --config .wippy.yaml test -- "app:$scenario" 2>&1) ||
     ! grep -Fq 'PASSED' <<< "$output"; then
    printf 'runner rejected valid %s:\n%s\n' "$scenario" "$output"
    exit 1
  fi
done
printf 'runner result and protocol regressions passed\n'

for scenario in empty_plan skipped_case returns_nil no-such-entry; do
  set +e
  output=$(WIPPY_TEST_REQUIRE_CASES=1 "$wippy_bin" test --config .wippy.yaml test -- "app:$scenario" 2>&1)
  status=$?
  set -e
  if [ "$status" -ne 1 ]; then
    printf 'required runner accepted %s (exit %s):\n%s\n' "$scenario" "$status" "$output"
    exit 1
  fi
done
if ! output=$("$wippy_bin" test --config .wippy.yaml test -- app:empty_plan 2>&1) ||
   ! grep -Fq 'PASSED' <<< "$output"; then
  printf 'runner rejected a generic empty plan:\n%s\n' "$output"
  exit 1
fi
printf 'required case regressions passed\n'
