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
