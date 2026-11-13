#!/usr/bin/env python3
"""Link the pinned Herdr source and managed personal configuration."""
import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


PACKAGE = Path(__file__).resolve().parent
DOTFILES_ROOT = PACKAGE.parents[1]
SOURCE_ROOT = PACKAGE / ".config/herdr-app"
SUBMODULE = DOTFILES_ROOT / "herdr-term"
SOURCE_TREE = SUBMODULE


def command_path(name):
    path = shutil.which(name)
    if path is None:
        raise RuntimeError(f"Required command not found: {name}")
    return str(Path(path).resolve(strict=True))


def run_checked(command, *, timeout=300):
    try:
        result = subprocess.run(
            command, text=True, capture_output=True, check=False, timeout=timeout
        )
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(
            f"Command timed out after {timeout}s: {' '.join(map(str, command))}"
        ) from error
    if result.returncode != 0:
        detail = "\n".join((result.stderr or result.stdout).strip().splitlines()[-20:])
        raise RuntimeError(
            f"Command failed ({result.returncode}): {' '.join(map(str, command))}"
            + (f"\n{detail}" if detail else "")
        )
    return result.stdout.strip()


def ensure_pinned_submodule():
    git = command_path("git")
    pinned = run_checked([git, "-C", str(DOTFILES_ROOT), "rev-parse", "HEAD:herdr-term"])
    if not re.fullmatch(r"[0-9a-f]{40}", pinned):
        raise RuntimeError("The dotfiles HEAD does not contain a pinned herdr-term submodule commit")

    if not (SUBMODULE / ".git").exists():
        print("Initializing herdr-term at the dotfiles-pinned commit", flush=True)
        run_checked([
            git, "-C", str(DOTFILES_ROOT), "submodule", "update", "--init", "--recursive", "--", "herdr-term",
        ])

    if not (SUBMODULE / ".git").exists():
        raise RuntimeError("herdr-term is still uninitialized after git submodule update")
    actual = run_checked([git, "-C", str(SUBMODULE), "rev-parse", "HEAD"])
    if actual != pinned:
        raise RuntimeError(
            f"herdr-term HEAD {actual} differs from the dotfiles pin {pinned}; "
            "refusing to change the checkout. To restore the pin, run: "
            "git submodule update --init --recursive -- herdr-term"
        )
    mods = SOURCE_TREE / "mods"
    if (
        SOURCE_TREE.is_symlink()
        or not SOURCE_TREE.is_dir()
        or mods.is_symlink()
        or not mods.is_dir()
        or not (SOURCE_TREE / "keys.json").is_file()
    ):
        raise RuntimeError(f"Pinned herdr source tree is missing: {SOURCE_TREE}")


def plan(home):
    if not home.is_absolute():
        raise ValueError("HOME must be an absolute path.")
    home = home.resolve()
    app = home / ".config/herdr-app"
    directories = [home / ".config"]
    links = []

    def visit(source, target):
        if source.is_symlink() or not source.is_dir():
            raise ValueError(f"Herdr source must be a real directory: {source}")
        directories.append(target)
        for entry in sorted(source.iterdir()):
            destination = target / entry.name
            if entry.is_dir() and not entry.is_symlink():
                visit(entry, destination)
            else:
                entry.resolve(strict=True)
                links.append((entry, destination))

    visit(SOURCE_ROOT, app)
    for container in (app / "mods", app / "data"):
        if container not in directories:
            directories.append(container)
    return home, app, directories, links


def install(home):
    home, app, directories, links = plan(home)
    for directory in directories:
        if directory.is_symlink() or (directory.exists() and not directory.is_dir()):
            raise ValueError(
                f"Refusing non-directory or linked container: {directory}. "
                "Use a real directory before installing."
            )

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
                shutil.copy2(target, saved, follow_symlinks=False)
            else:
                raise ValueError(f"Refusing special file at managed path: {target}")

        descriptor, temporary_name = tempfile.mkstemp(prefix=".dotfiles-link-", dir=target.parent)
        os.close(descriptor)
        temporary = Path(temporary_name)
        try:
            temporary.unlink()
            temporary.symlink_to(expected, target_is_directory=source.is_dir())
            os.replace(temporary, target)
        finally:
            temporary.unlink(missing_ok=True)
    return backup


def main():
    parser = argparse.ArgumentParser(
        description=__doc__,
        epilog="Normally run: bash stow/install.sh herdr. Unmanaged Herdr settings and runtime state are untouched.",
    )
    parser.add_argument("--prepare", action="store_true", help="initialize and validate the pinned source without linking")
    args = parser.parse_args()
    try:
        home = Path(os.environ["HOME"])
        if args.prepare:
            ensure_pinned_submodule()
            return 0
        if os.environ.get("HERDR_PREPARED") != "true":
            ensure_pinned_submodule()
        install(home)
    except (OSError, ValueError, RuntimeError, KeyError) as error:
        print(f"Herdr install failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
