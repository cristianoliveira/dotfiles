#!/usr/bin/env python3
"""Prepare pinned Herdr mods and link repository-managed app-home paths."""
import argparse
import hashlib
import json
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
DEV_MODS_FILE = PACKAGE / "dev-mods.txt"
DEV_LOOP = SUBMODULE / "scripts/dev-loop.mjs"
GENERATION_FILE = ".muxcle-dev-generation.json"
OWNER_FILE = ".muxcle-dev-loop.json"
MOD_NAME = re.compile(r"^[a-z0-9][a-z0-9-]*$")
GENERATION_ID = re.compile(r"^[a-z0-9][a-z0-9-]*$")


def read_dev_mods(path=DEV_MODS_FILE):
    mods = []
    seen = set()
    for line_number, raw_line in enumerate(Path(path).read_text().splitlines(), 1):
        name = raw_line.partition("#")[0].strip()
        if not name:
            continue
        if not MOD_NAME.fullmatch(name):
            raise ValueError(f"Invalid Herdr mod name on {path}:{line_number}: {name!r}")
        if name in seen:
            raise ValueError(f"Duplicate Herdr mod in {path}:{line_number}: {name}")
        if (SOURCE_ROOT / "mods" / name).exists() or (SOURCE_ROOT / "mods" / name).is_symlink():
            raise ValueError(f"{name} is already owned by the Stow Herdr package; refusing a development link")
        seen.add(name)
        mods.append(name)
    return mods


def command_path(name):
    path = shutil.which(name)
    if path is None:
        raise RuntimeError(
            f"Required development command not found: {name}. Install {name}, then rerun: make setup"
        )
    return str(Path(path).resolve(strict=True))


def run_checked(command, *, cwd=None, timeout=300):
    try:
        result = subprocess.run(
            command, cwd=cwd, text=True, capture_output=True, check=False, timeout=timeout
        )
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(f"Command timed out after {timeout}s: {' '.join(map(str, command))}") from error
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
    if not DEV_LOOP.is_file():
        raise RuntimeError(f"Pinned herdr-term development loop is missing: {DEV_LOOP}")


def validate_installed_typescript(child, locked_version):
    package_file = child / "node_modules/typescript/package.json"
    compiler = child / "node_modules/.bin/tsc"
    if not compiler.is_file() or not os.access(compiler, os.X_OK) or not package_file.is_file():
        return False
    try:
        return json.loads(package_file.read_text()).get("version") == locked_version
    except (OSError, json.JSONDecodeError):
        return False


def ensure_dev_tools():
    node = command_path("node")
    npm = command_path("npm")
    node_version = run_checked([node, "--version"])
    npm_version = run_checked([npm, "--version"])
    if node_version != "v22.23.4" or npm_version != "10.9.9":
        raise RuntimeError(
            "Herdr development requires Node.js 22.23.4 and npm 10.9.9; "
            f"found {node_version} and npm {npm_version}. Activate Node.js 22.23.4, then run "
            "`npm install --global npm@10.9.9 --ignore-scripts` and retry `make setup`."
        )

    lockfile = SUBMODULE / "package-lock.json"
    package = SUBMODULE / "package.json"
    if not lockfile.is_file() or not package.is_file():
        raise RuntimeError("Pinned herdr-term is missing its npm manifests")
    lock_hash = hashlib.sha256(lockfile.read_bytes()).hexdigest()
    locked_version = json.loads(lockfile.read_text())["packages"]["node_modules/typescript"]["version"]
    marker = SUBMODULE / "node_modules/.herdr-dev-lock-sha256"
    marker_matches = False
    if marker.is_file() and not marker.is_symlink():
        marker_matches = marker.read_text().strip() == lock_hash

    if not marker_matches or not validate_installed_typescript(SUBMODULE, locked_version):
        print("Installing locked Herdr development tools (npm lifecycle scripts disabled)", flush=True)
        run_checked([npm, "ci", "--ignore-scripts"], cwd=SUBMODULE, timeout=600)
        if not validate_installed_typescript(SUBMODULE, locked_version):
            raise RuntimeError(f"npm ci did not install locked TypeScript {locked_version}")
        marker.write_text(f"{lock_hash}\n")


def load_generation_metadata(path, description):
    if path.is_symlink():
        raise RuntimeError(f"dev-loop {description} is linked: {path}")
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        raise RuntimeError(f"dev-loop {description} is missing or invalid: {path}") from error


def validate_mod_payload(mod_name, home):
    mod_directory = home / "mods" / mod_name
    for path in (home, home / "mods", mod_directory):
        if path.is_symlink() or not path.is_dir():
            raise RuntimeError(f"dev-loop output is incomplete for {mod_name}: {path}")
    for filename in ("mod.json", "main.js", "package-owner.json"):
        path = mod_directory / filename
        if path.is_symlink() or not path.is_file():
            raise RuntimeError(f"dev-loop output is incomplete for {mod_name}: {path}")
    package_owner = load_generation_metadata(
        mod_directory / "package-owner.json", f"package ownership for {mod_name}"
    )
    if package_owner != {"package": mod_name, "schema": 1}:
        raise RuntimeError(f"dev-loop package ownership does not match {mod_name}")


def validate_generation_metadata(mod_name, generation_id, managed_root, generation_root):
    owner = load_generation_metadata(managed_root / OWNER_FILE, "generation owner")
    generation = load_generation_metadata(generation_root / GENERATION_FILE, "generation metadata")
    if (
        owner.get("schema") != 1
        or generation.get("schema") != 1
        or owner.get("projectId") != generation.get("projectId")
    ):
        raise RuntimeError(f"dev-loop generation ownership is invalid for {mod_name}")
    if generation.get("id") != generation_id or generation.get("modName") != mod_name:
        raise RuntimeError(f"dev-loop generation metadata does not match {mod_name}")


def validate_generation(mod_name, output):
    lines = output.splitlines()
    if len(lines) < 2:
        raise RuntimeError(f"dev-loop build returned incomplete output for {mod_name}")
    match = re.fullmatch(rf"Built {re.escape(mod_name)} generation ([a-z0-9-]+)", lines[0])
    if not match or not GENERATION_ID.fullmatch(match.group(1)):
        raise RuntimeError(f"dev-loop build returned an invalid generation for {mod_name}")

    generation_id = match.group(1)
    reported_home = Path(lines[1])
    if reported_home.is_symlink():
        raise RuntimeError(f"dev-loop output is linked for {mod_name}: {reported_home}")
    home = reported_home.resolve(strict=True)
    managed_root = (SUBMODULE / ".build/dev-generations").resolve(strict=True)
    try:
        home.relative_to(managed_root)
    except ValueError as error:
        raise RuntimeError(f"dev-loop output for {mod_name} is outside managed generation storage") from error

    generation_root = home.parent
    if generation_root.name != generation_id or home.name != "home":
        raise RuntimeError(f"dev-loop returned an unexpected generation home for {mod_name}")
    validate_generation_metadata(mod_name, generation_id, managed_root, generation_root)
    validate_mod_payload(mod_name, home)
    return generation_id


def build_selected_mods(mods):
    if not mods:
        return
    node = command_path("node")
    for mod_name in mods:
        output = run_checked([node, str(DEV_LOOP), "build", "--mod", mod_name], cwd=SUBMODULE)
        generation_id = validate_generation(mod_name, output)
        print(f"Validated {mod_name} generation {generation_id}", flush=True)


def plan(home):
    if not home.is_absolute():
        raise ValueError("HOME must be an absolute path.")
    home = home.resolve()
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

    visit(SOURCE_ROOT, home / ".config/herdr-app")
    return home, home / ".config/herdr-app", directories, links


def preflight(home, mods):
    home, app, directories, _links = plan(home)
    for directory in directories:
        if directory.is_symlink() or (directory.exists() and not directory.is_dir()):
            raise ValueError(
                f"Refusing non-directory or linked container: {directory}. "
                "Use a real directory before installing."
            )

    if not mods:
        return
    node = command_path("node")
    for mod_name in mods:
        target = app / "mods" / mod_name
        if not target.exists() and not target.is_symlink():
            continue
        try:
            result = subprocess.run(
                [node, str(DEV_LOOP), "status", "--mod", mod_name, "--app-home", str(app)],
                cwd=SUBMODULE,
                text=True,
                capture_output=True,
                check=False,
                timeout=30,
            )
        except subprocess.TimeoutExpired as error:
            raise ValueError(f"Timed out verifying the existing development link: {target}") from error
        if result.returncode != 0:
            detail = "\n".join((result.stderr or result.stdout).strip().splitlines()[-10:])
            raise ValueError(
                f"Refusing existing {mod_name} target; it is not a verified Herdr development link: "
                f"{target}. Preserve or remove it deliberately before setup."
                + (f"\n{detail}" if detail else "")
            )
        try:
            status = json.loads(result.stdout)
        except json.JSONDecodeError as error:
            raise ValueError(f"dev-loop returned invalid status for {mod_name}: {target}") from error
        if not status.get("active") or status.get("mod") != mod_name:
            raise ValueError(f"Refusing unverified Herdr development target: {target}")


def prepare(home):
    mods = read_dev_mods()
    ensure_pinned_submodule()
    # Reject foreign ownership before spending time installing or building anything.
    preflight(home, mods)
    if mods:
        ensure_dev_tools()
        build_selected_mods(mods)
    # Recheck after builds to catch a target created while preparation was running.
    preflight(home, mods)


def install(home):
    mods = read_dev_mods()
    home, app, directories, links = plan(home)
    preflight(home, mods)

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

    if mods:
        node = command_path("node")
        for mod_name in mods:
            run_checked([
                node, str(DEV_LOOP), "link", "--mod", mod_name, "--app-home", str(app),
            ], cwd=SUBMODULE)
    return backup


def main():
    parser = argparse.ArgumentParser(
        description=__doc__,
        epilog=(
            "Normally run: bash stow/install.sh herdr. The prepare phase validates the pinned "
            "submodule, build output, and selected module targets before creating links."
        ),
    )
    parser.add_argument("--prepare", action="store_true", help="initialize/build selected mods and preflight without linking")
    args = parser.parse_args()
    try:
        home = Path(os.environ["HOME"])
        if args.prepare:
            prepare(home)
            return 0
        if os.environ.get("HERDR_DEV_PREPARED") != "true":
            prepare(home)
        install(home)
    except (OSError, ValueError, RuntimeError, KeyError, json.JSONDecodeError) as error:
        print(f"Herdr install failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
