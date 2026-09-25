#!/usr/bin/env python3
"""Print the changelog section for one version of a release-please CHANGELOG.md.

With --line the section is condensed to one line ("Features: a; b. Bug Fixes: c."),
because wippy publish sends release notes in an HTTP header, which cannot carry
line breaks."""

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


LINK = re.compile(r"\s*\(\[[^\]]*\]\([^)]*\)\)")
MARKUP = re.compile(r"\[([^\]]*)\]\([^)]*\)|\*\*")


def one_line(body: str) -> str:
    groups: list[str] = []
    heading, entries = "", []
    for line in body.splitlines() + ["### "]:
        if line.startswith("### "):
            if entries:
                groups.append(f"{heading}: " + "; ".join(entries) + ".")
            heading, entries = line[4:].strip(), []
        elif line.startswith("* "):
            entry = MARKUP.sub(lambda m: m.group(1) or "", LINK.sub("", line[2:])).strip()
            entries.append(entry)
    return " ".join(groups) + "\n"


def main(argv: list[str]) -> int:
    args = [a for a in argv[1:] if a != "--line"]
    if len(args) != 2:
        print("usage: release_notes.py [--line] <CHANGELOG.md> <version>", file=sys.stderr)
        return 2
    path, version = Path(args[0]), args[1]
    try:
        body = section(path.read_text(), version)
        sys.stdout.write(one_line(body) if "--line" in argv else body)
    except (OSError, ValueError) as error:
        print(f"{path}: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
