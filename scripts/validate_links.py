#!/usr/bin/env python3
"""Validate Markdown links in AGENTS.md files.

Every inline Markdown link must resolve to an existing AGENTS.md file relative to
the originating guide's folder. External, escaping, missing, directory, and
non-AGENTS.md targets are rejected.
"""

import os
import re
import sys
from pathlib import Path

LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
EXCLUDED_DIRS = {".gwt", ".git", ".tmp"}


def find_agents_files(root: Path):
    results = []
    for path in root.rglob("AGENTS.md"):
        # Skip files inside excluded directories (e.g. git worktrees).
        parts = set(path.relative_to(root).parts[:-1])
        if parts & EXCLUDED_DIRS:
            continue
        results.append(path)
    return sorted(results)


def validate(root: Path):
    errors = []
    agents_files = find_agents_files(root)
    root_resolved = root.resolve()
    for source in agents_files:
        text = source.read_text(encoding="utf-8")
        for match in LINK_RE.finditer(text):
            label, target = match.group(1), match.group(2)
            # Skip anchor-only links.
            if target.startswith("#"):
                continue
            # Reject external links.
            if re.match(r"^[a-z][a-z0-9+.-]*://", target, re.IGNORECASE):
                errors.append((source, label, target, "external URL"))
                continue
            resolved = (source.parent / target).resolve()
            try:
                resolved.relative_to(root_resolved)
            except ValueError:
                errors.append((source, label, target, "escapes repository"))
                continue
            if resolved.is_dir():
                errors.append((source, label, target, "points to directory"))
                continue
            if not resolved.exists():
                errors.append((source, label, target, "missing target"))
                continue
            if resolved.name != "AGENTS.md":
                errors.append((source, label, target, "not an AGENTS.md file"))
                continue
    return errors


def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    errors = validate(root)
    if errors:
        print(f"Found {len(errors)} invalid link(s):")
        for source, label, target, reason in errors:
            rel_source = source.relative_to(root)
            print(f"  {rel_source}: [{label}]({target}) -> {reason}")
        sys.exit(1)
    print("All AGENTS.md links are valid.")


if __name__ == "__main__":
    main()
