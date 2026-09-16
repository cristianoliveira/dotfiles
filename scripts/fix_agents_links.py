#!/usr/bin/env python3
"""Rewrite AGENTS.md Markdown links so they resolve from each file's folder.

Links that are currently repository-root-relative are converted to paths relative
to the originating AGENTS.md file. Links that already resolve from the file's
folder are left unchanged.
"""

import os
import re
import sys
from pathlib import Path

LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
EXCLUDED_DIRS = {".gwt", ".git", ".tmp"}


def find_agents_files(root: Path):
    for path in root.rglob("AGENTS.md"):
        parts = set(path.relative_to(root).parts[:-1])
        if parts & EXCLUDED_DIRS:
            continue
        yield path


def fix_link(source: Path, target: str, root: Path):
    # Leave anchors and external links alone.
    if target.startswith("#") or re.match(r"^[a-z][a-z0-9+.-]*://", target, re.IGNORECASE):
        return target

    from_file = source.parent / target
    if from_file.resolve().exists():
        # Already resolves from the source folder.
        return target

    from_root = root / target
    if not from_root.exists():
        # Cannot determine intended target; leave as-is so validation flags it.
        return target

    # Compute a relative path from the source file's folder to the target.
    rel = os.path.relpath(from_root.resolve(), source.parent.resolve())
    return rel


def fix_file(source: Path, root: Path):
    text = source.read_text(encoding="utf-8")

    def repl(match):
        label, target = match.group(1), match.group(2)
        new_target = fix_link(source, target, root)
        return f"[{label}]({new_target})"

    new_text = LINK_RE.sub(repl, text)
    if new_text != text:
        source.write_text(new_text, encoding="utf-8")
        print(f"Updated {source.relative_to(root)}")


def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    root = root.resolve()
    for source in find_agents_files(root):
        fix_file(source, root)


if __name__ == "__main__":
    main()
