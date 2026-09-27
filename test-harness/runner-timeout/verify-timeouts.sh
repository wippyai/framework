#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
for scenario in timeout_late timeout_silent; do
  set +e
  output=$(wippy run -x wippy.test:runner --config .wippy.yaml -- "$scenario" 2>&1)
  status=$?
  set -e
  if ! grep -q 'FAILED' <<< "$output" || ! grep -q 'test timed out' <<< "$output" ||
     ! grep -q "${scenario}_next" <<< "$output" ||
     ! grep -q '1 passed' <<< "$output" || ! grep -q '1 failed' <<< "$output" ||
     grep -q 'late_pass' <<< "$output" ||
     grep -q 'completion counts disagree\|test process termination failed\|test cancellation failed' <<< "$output"; then
    printf 'runner timeout scenario %s failed verification:\n%s\n' "$scenario" "$output"
    exit 1
  fi
done
printf 'real runner timeout scenarios passed\n'
