#!/usr/bin/env python3
"""Require explicit package types for every Framework module and test app, and
every module registered as a release-please package."""

from pathlib import Path
import json
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
            errors.append(f"{path.relative_to(ROOT)}: versions come from .release-please-manifest.json")

    packages = {"/".join(path.relative_to(ROOT).parts[:2]) for path in manifests}
    released = set(json.loads((ROOT / ".release-please-manifest.json").read_text()))
    configured = set(json.loads((ROOT / "release-please-config.json").read_text())["packages"])
    for package in sorted(packages | released | configured):
        if package not in packages:
            errors.append(f"{package}: release-please lists a package with no module wippy.yaml")
        if package not in released:
            errors.append(f"{package}: missing from .release-please-manifest.json")
        if package not in configured:
            errors.append(f"{package}: missing from release-please-config.json")
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
