#!/usr/bin/env python3
"""Validate landmark and boundary-flow declarations in AGENTS.md files.

Landmarks must use repository-root-relative source paths and public symbols in the
form `<source-path>:<public-symbol>`. Boundary flows must follow the prescribed
single-line format. This script checks that referenced source files exist.
"""

import re
import sys
from pathlib import Path

EXCLUDED_DIRS = {".gwt", ".git", ".tmp"}
LANDMARK_RE = re.compile(r"^-\s+`([^`]+):([^`]+)`")
FLOW_RE = re.compile(
    r"^-\s+Information flow:\s+`([^`]+):([^`]+)`\s+->\s+`([^`]+):([^`]+)`\s+via\s+`([^`]+):([^`]+)`;\s+value:\s+`([^`]+)`"
)


def find_agents_files(root: Path):
    for path in root.rglob("AGENTS.md"):
        parts = set(path.relative_to(root).parts[:-1])
        if parts & EXCLUDED_DIRS:
            continue
        yield path


def validate(root: Path):
    errors = []
    root_resolved = root.resolve()
    for source in find_agents_files(root):
        text = source.read_text(encoding="utf-8")
        in_landmarks = False
        in_flows = False
        for line in text.splitlines():
            stripped = line.strip()
            if stripped == "# Landmarks":
                in_landmarks = True
                in_flows = False
                continue
            if stripped == "# Boundary flows":
                in_landmarks = False
                in_flows = True
                continue
            if stripped.startswith("# "):
                in_landmarks = False
                in_flows = False
                continue
            if in_landmarks and stripped.startswith("- "):
                match = LANDMARK_RE.match(stripped)
                if not match:
                    errors.append((source, stripped, "malformed landmark"))
                    continue
                src_path, symbol = match.group(1), match.group(2)
                full_path = root_resolved / src_path
                if not full_path.exists():
                    errors.append((source, stripped, f"missing source file: {src_path}"))
                elif not full_path.is_file():
                    errors.append((source, stripped, f"not a file: {src_path}"))
            if in_flows and stripped.startswith("- "):
                if not FLOW_RE.match(stripped):
                    errors.append((source, stripped, "malformed boundary flow"))
    return errors


def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    errors = validate(root)
    if errors:
        print(f"Found {len(errors)} invalid landmark/flow declaration(s):")
        for source, line, reason in errors:
            rel_source = source.relative_to(root)
            print(f"  {rel_source}: {line} -> {reason}")
        sys.exit(1)
    print("All landmark and boundary-flow declarations are valid.")


if __name__ == "__main__":
    main()
