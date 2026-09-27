#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
set +e
output=$(wippy test --config .wippy.yaml 2>&1)
status=$?
set -e
if [ "$status" -eq 0 ]; then
  printf 'runner accepted a failing hook:\n%s\n' "$output"
  exit 1
fi
if ! printf '%s\n' "$output" | grep -q 'expected hook failure before second case'; then
  printf 'runner failed for an unrelated reason:\n%s\n' "$output"
  exit 1
fi
if ! printf '%s\n' "$output" | grep -q 'FAILED'; then
  printf 'runner did not report FAILED:\n%s\n' "$output"
  exit 1
fi
printf 'hook abort fails the run as expected\n'
