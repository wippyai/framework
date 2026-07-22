#!/usr/bin/env python3
"""Require explicit package types for every Framework module and test app."""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]


def scalar(path: Path, field: str) -> str | None:
    pattern = re.compile(rf"^{re.escape(field)}:\s*([^#\s]+)", re.MULTILINE)
    match = pattern.search(path.read_text())
    return match.group(1).strip("'\"") if match else None


def main() -> int:
    errors: list[str] = []
    manifests = sorted((ROOT / "src").glob("*/wippy.yaml"))
    manifests += sorted((ROOT / "src").glob("*/src/wippy.yaml"))
    test_manifests = sorted((ROOT / "src").glob("*/test/wippy.yaml"))

    for path in manifests:
        if scalar(path, "type") != "library":
            errors.append(f"{path.relative_to(ROOT)}: Framework packages must declare type: library")
        if scalar(path, "version") is not None:
            errors.append(f"{path.relative_to(ROOT)}: Hub selects package versions")
    for path in test_manifests:
        if scalar(path, "type") != "application":
            errors.append(f"{path.relative_to(ROOT)}: test harnesses must declare type: application")

    if errors:
        print("Module manifest conventions failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1
    print(f"Module manifest conventions passed: {len(manifests)} libraries; {len(test_manifests)} test applications.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
