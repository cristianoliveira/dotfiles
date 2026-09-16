#!/usr/bin/env python3
"""Identify candidate AGENTS.md modules from the repository source tree.

Uses `git ls-files --cached --others --exclude-standard` so Git's ignore rules
define the files under evaluation. For every source-bearing directory, reports
whether it should be include, parent, review, or exclude.
"""

import argparse
import json
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

EXCLUDED_DIRS = {".gwt", ".git", ".tmp", "node_modules", ".direnv"}
SMALL_FILE_COUNT = 3
SMALL_LINE_COUNT = 50


def git_ls_files(root: Path):
    result = subprocess.run(
        ["git", "-C", str(root), "ls-files", "--cached", "--others", "--exclude-standard"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(result.stderr, file=sys.stderr)
        sys.exit(1)
    return [root / line for line in result.stdout.splitlines() if line]


def is_source_file(path: Path):
    # Skip hidden files, lock files, documentation, and binary assets.
    name = path.name
    if name.startswith("."):
        return False
    if name in {"flake.lock", "AGENTS.md", "README.md", "DEVELOPMENT.md"}:
        return False
    binary_suffixes = {
        ".png", ".jpg", ".jpeg", ".gif", ".webp", ".icns", ".ico", ".ttf", ".otf",
        ".woff", ".woff2", ".mp3", ".mp4", ".mov", ".avi", ".pdf", ".zip", ".tar",
        ".gz", ".bz2", ".xz", ".dmg", ".app", ".plist", ".nib", ".car", ".strings",
        ".bin", ".so", ".dylib", ".dll", ".exe", ".o", ".a", ".framework",
    }
    if path.suffix.lower() in binary_suffixes:
        return False
    if ".app/" in str(path) or str(path).endswith(".app"):
        return False
    return path.is_file()


def line_count(path: Path):
    try:
        return len(path.read_text(encoding="utf-8", errors="ignore").splitlines())
    except Exception:
        return 0


def gather_dirs(root: Path, files):
    root_parts = root.resolve().parts
    root_depth = len(root_parts)
    dirs = defaultdict(lambda: {"files": [], "subdirs": set(), "has_agents": False})
    for f in files:
        f_resolved = f.resolve()
        try:
            f_resolved.relative_to(root.resolve())
        except ValueError:
            continue
        parts = f_resolved.parts
        # Only consider directories below root.
        for i in range(root_depth, len(parts) - 1):
            part = parts[i]
            if part in EXCLUDED_DIRS:
                break
            d = Path(*parts[: i + 1])
            dirs[d]["files"].append(f_resolved)
            if i + 2 < len(parts):
                dirs[d]["subdirs"].add(parts[i + 1])
            if f_resolved.name == "AGENTS.md":
                dirs[d]["has_agents"] = True
    return dirs


def has_public_exports(files):
    # Heuristic: shell scripts with executable bit, Makefile targets, or Nix options.
    for f in files:
        if f.suffix in {".sh", ".nix", ".lua"}:
            return True
        if f.name == "Makefile":
            return True
        if f.stat().st_mode & 0o111:
            return True
    return False


def has_entrypoint(files):
    entry_names = {"init.lua", "setup.sh", "install.sh", "configuration.nix", "flake.nix", "main.py"}
    return any(f.name in entry_names for f in files)


def decision(d):
    source_files = [f for f in d["files"] if is_source_file(f)]
    source_dirs = d["subdirs"]
    total_lines = sum(line_count(f) for f in source_files)
    src_count = len(source_files)

    if not source_files:
        return "exclude"

    # Test/mock/fixture-only directories.
    if all(
        "test" in str(f).lower() or "mock" in str(f).lower() or "fixture" in str(f).lower()
        for f in source_files
    ):
        return "exclude"

    signals = sum(
        [
            src_count > 1,
            len(source_dirs) > 1,
            has_public_exports(source_files),
            has_entrypoint(source_files),
            total_lines > SMALL_LINE_COUNT,
        ]
    )

    if signals >= 2 and (src_count >= SMALL_FILE_COUNT or total_lines >= SMALL_LINE_COUNT):
        return "include"
    if src_count < SMALL_FILE_COUNT and total_lines < SMALL_LINE_COUNT:
        return "parent"
    return "review"


def main():
    parser = argparse.ArgumentParser(description="Identify AGENTS.md module candidates")
    parser.add_argument("root", type=Path, default=Path.cwd(), nargs="?")
    parser.add_argument("--format", choices=["table", "json"], default="table")
    parser.add_argument("--all", action="store_true", help="Include exclude decisions in output")
    args = parser.parse_args()

    root = args.root.resolve()
    files = git_ls_files(root)
    dirs = gather_dirs(root, files)

    results = []
    for d, info in sorted(dirs.items()):
        if d == root:
            continue
        dec = decision(info)
        if not args.all and dec == "exclude":
            continue
        source_files = [f for f in info["files"] if is_source_file(f)]
        results.append(
            {
                "directory": str(d.relative_to(root)),
                "decision": dec,
                "files": len(source_files),
                "lines": sum(line_count(f) for f in source_files),
                "subdirs": len(info["subdirs"]),
                "has_agents": info["has_agents"],
            }
        )

    if args.format == "json":
        print(json.dumps(results, indent=2))
    else:
        print(f"{'Directory':<40} {'Decision':<8} {'Files':>6} {'Lines':>7} {'Subdirs':>7} {'Agents':>7}")
        for r in results:
            print(
                f"{r['directory']:<40} {r['decision']:<8} {r['files']:>6} {r['lines']:>7} {r['subdirs']:>7} {'yes' if r['has_agents'] else 'no':>7}"
            )


if __name__ == "__main__":
    main()
