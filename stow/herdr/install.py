#!/usr/bin/env python3
"""Give repository-managed Herdr paths precedence, preserving replaced configs."""
import argparse
import os
from pathlib import Path
import shutil
import sys
import tempfile


PACKAGE = Path(__file__).resolve().parent


def install(home):
    if not home.is_absolute():
        raise ValueError("HOME must be an absolute path.")
    home = home.resolve()
    source_root = PACKAGE / ".config/herdr-app"
    app = home / ".config/herdr-app"
    directories = [home / ".config"]
    links = []

    def plan(source, target):
        directories.append(target)
        for entry in sorted(source.iterdir()):
            destination = target / entry.name
            if entry.is_dir() and not entry.is_symlink():
                plan(entry, destination)
            else:
                entry.resolve(strict=True)
                links.append((entry, destination))

    plan(source_root, app)
    # Check every mutable container before replacing any managed leaf.
    for directory in directories:
        if directory.is_symlink() or (directory.exists() and not directory.is_dir()):
            raise ValueError(f"Refusing non-directory or linked container: {directory}. Use a real directory before installing.")
    for directory in directories:
        directory.mkdir(parents=True, exist_ok=True)

    backup = None
    for source, target in links:
        expected = os.path.relpath(source, target.parent)
        if target.is_symlink() and os.readlink(target) == expected:
            continue

        if target.exists() or target.is_symlink():
            if backup is None:
                backup = Path(tempfile.mkdtemp(prefix="herdr-app.backup.", dir=home / ".config"))
                print(f"Preserving replaced Herdr configs in {backup}", flush=True)
            saved = backup / target.relative_to(app)
            saved.parent.mkdir(parents=True, exist_ok=True)
            if target.is_dir() and not target.is_symlink():
                target.rename(saved)
            elif target.is_symlink() or target.is_file():
                # Copy without unlinking: a running app must never see missing keys.
                shutil.copy2(target, saved, follow_symlinks=False)
            else:
                raise ValueError(f"Refusing special file at managed path: {target}")

        descriptor, temporary_name = tempfile.mkstemp(prefix=".dotfiles-link-", dir=target.parent)
        os.close(descriptor)
        temporary = Path(temporary_name)
        try:
            temporary.unlink()
            temporary.symlink_to(expected)
            os.replace(temporary, target)
        finally:
            temporary.unlink(missing_ok=True)
    return backup


def main():
    parser = argparse.ArgumentParser(description=__doc__,
        epilog="Normally run: bash stow/install.sh herdr. Settings, sessions and unmanaged paths are untouched.")
    parser.parse_args()
    try:
        install(Path(os.environ["HOME"]))
    except (OSError, ValueError) as error:
        print(f"Herdr install failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
