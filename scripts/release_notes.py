#!/usr/bin/env python3
"""Print the changelog section for one version of a release-please CHANGELOG.md."""

from pathlib import Path
import re
import sys


def section(changelog: str, version: str) -> str:
    heading = re.compile(rf"^## \[?{re.escape(version)}\]?(?:\(|\s|$)", re.MULTILINE)
    start = heading.search(changelog)
    if start is None:
        raise ValueError(f"version {version} has no changelog section")
    rest = changelog[start.end():]
    end = re.search(r"^## ", rest, re.MULTILINE)
    body = rest[: end.start()] if end else rest
    body = body[body.find("\n") + 1 :] if "\n" in body else ""
    return body.strip() + "\n"


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("usage: release_notes.py <CHANGELOG.md> <version>", file=sys.stderr)
        return 2
    path, version = Path(argv[1]), argv[2]
    try:
        sys.stdout.write(section(path.read_text(), version))
    except (OSError, ValueError) as error:
        print(f"{path}: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
