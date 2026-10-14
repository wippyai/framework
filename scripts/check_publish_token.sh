#!/usr/bin/env bash
set -euo pipefail

if [ -z "${WIPPY_TOKEN:-}" ]; then
  echo "WIPPY_TOKEN secret is required to publish to the Wippy hub" >&2
  exit 1
fi
