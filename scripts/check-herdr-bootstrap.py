#!/usr/bin/env python3
"""Exercise the pinned Herdr setup against disposable app homes."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
CHILD = ROOT / "herdr-term"
BASH = Path("/bin/bash").resolve(strict=True)
FORBIDDEN = ("nix", "nix-shell", "herdr-app", "hc")


def require_tool(name, search_path):
    found = shutil.which(name, path=search_path)
    if found is None:
        raise RuntimeError(f"Required integration tool is missing: {name}")
    return Path(found).resolve(strict=True)


def write_executable(path, content):
    path.write_text(content)
    path.chmod(0o755)
    if path.resolve(strict=True).parent != path.parent.resolve(strict=True):
        raise RuntimeError(f"Mock command escaped its controlled directory: {path}")


def validate_mocks(mock_bin, search_path):
    for name in ("stow", *FORBIDDEN):
        path = require_tool(name, search_path)
        if path.parent != mock_bin.resolve():
            raise RuntimeError(f"Expected controlled {name} mock, resolved to {path}")
    for name in ("git", "node", "npm", "python3"):
        print(f"Using {name}: {require_tool(name, search_path)}")
    if BASH != Path("/bin/bash").resolve(strict=True):
        raise RuntimeError("Unexpected bash executable")


def run_setup(home, search_path, trace, *, check=True):
    environment = os.environ.copy()
    environment.update({
        "HOME": str(home),
        "PATH": search_path,
        "HERDR_STOW_TRACE": str(trace),
    })
    result = subprocess.run(
        [str(BASH), str(ROOT / "stow/install.sh"), "herdr"],
        cwd=ROOT,
        env=environment,
        text=True,
        capture_output=True,
        timeout=180,
        check=False,
    )
    if check and result.returncode != 0:
        raise AssertionError(f"Herdr setup failed ({result.returncode}):\n{result.stdout}\n{result.stderr}")
    return result


def active_generation(app_home, node):
    result = subprocess.run(
        [str(node), str(CHILD / "scripts/dev-loop.mjs"), "status", "--mod", "muxcle-picker", "--app-home", str(app_home)],
        text=True,
        capture_output=True,
        timeout=30,
        check=False,
    )
    if result.returncode != 0:
        raise AssertionError(f"dev-loop status failed:\n{result.stdout}\n{result.stderr}")
    return json.loads(result.stdout)["active"]


def generation_count():
    root = CHILD / ".build/dev-generations"
    if not root.exists():
        return 0
    return sum(path.is_dir() and not path.name.startswith(".") for path in root.iterdir())


def main():
    if not (CHILD / ".git").exists():
        raise RuntimeError("CI checkout must initialize herdr-term recursively")

    with tempfile.TemporaryDirectory(prefix="herdr-bootstrap-") as temporary:
        work = Path(temporary)
        mock_bin = work / "mock-bin"
        mock_bin.mkdir()
        trace = work / "stow.log"
        forbidden_trace = work / "forbidden.log"
        write_executable(
            mock_bin / "stow",
            '#!/bin/sh\nprintf "%s\\n" "$*" >> "$HERDR_STOW_TRACE"\n',
        )
        for name in FORBIDDEN:
            write_executable(
                mock_bin / name,
                f'#!/bin/sh\nprintf "{name}\\n" >> "{forbidden_trace}"\nexit 97\n',
            )

        search_path = f"{mock_bin}:{os.environ.get('PATH', '/usr/bin:/bin')}"
        validate_mocks(mock_bin, search_path)
        node = require_tool("node", search_path)

        home = work / "home"
        (home / ".dotfiles/stow").mkdir(parents=True)
        (home / ".dotfiles/stow/common.sh").symlink_to(ROOT / "stow/common.sh")
        app_home = home / ".config/herdr-app"
        app_home.mkdir(parents=True)
        settings = app_home / "settings.json"
        settings.write_text('{"preserve": true}\n')

        result = run_setup(home, search_path, trace)
        target = app_home / "mods/muxcle-picker"
        if not target.is_symlink():
            raise AssertionError("setup did not create the selected development link")
        link_target = target.resolve(strict=True)
        managed_root = (CHILD / ".build/dev-generations").resolve(strict=True)
        if managed_root not in link_target.parents:
            raise AssertionError(f"development link escaped managed generations: {link_target}")
        if not active_generation(app_home, node):
            raise AssertionError("dev-loop does not report the selected generation as active")
        if settings.read_text() != '{"preserve": true}\n':
            raise AssertionError("setup changed an unmanaged app-home setting")

        keys = app_home / "keys.json"
        layout = app_home / "layouts/tmux.json"
        if keys.read_bytes() != (ROOT / "stow/herdr/.config/herdr-app/keys.json").read_bytes():
            raise AssertionError("setup changed the existing keys configuration")
        if layout.read_bytes() != (ROOT / "stow/herdr/.config/herdr-app/layouts/tmux.json").read_bytes():
            raise AssertionError("setup changed the existing layout configuration")
        legacy_picker = app_home / "mods/tmux-picker"
        if not legacy_picker.is_symlink() or legacy_picker.resolve() != (
            ROOT / "stow/herdr/.config/herdr-app/mods/tmux-picker"
        ).resolve():
            raise AssertionError("setup replaced the existing Stow-owned picker")
        if forbidden_trace.exists():
            raise AssertionError(f"native/Nix command was invoked: {forbidden_trace.read_text()}")

        # A foreign link at the selected name must stop before config changes or builds.
        conflict_home = work / "conflict-home"
        conflict_app = conflict_home / ".config/herdr-app"
        (conflict_app / "mods").mkdir(parents=True)
        conflict_keys = conflict_app / "keys.json"
        conflict_keys.write_text("preserve this file\n")
        foreign_target = work / "foreign-mod"
        foreign_target.mkdir()
        foreign_link = conflict_app / "mods/muxcle-picker"
        foreign_link.symlink_to(foreign_target, target_is_directory=True)
        before_generations = generation_count()
        failed = run_setup(conflict_home, search_path, trace, check=False)
        if failed.returncode == 0:
            raise AssertionError("setup unexpectedly replaced a foreign module link")
        if (
            conflict_keys.read_text() != "preserve this file\n"
            or foreign_link.resolve() != foreign_target.resolve()
        ):
            raise AssertionError("foreign-link preflight changed the app home")
        if generation_count() != before_generations:
            raise AssertionError("foreign-link preflight built a generation before refusing")

        # A compile failure must not move a previously active development link.
        old_link = target.readlink()
        before_stow_calls = trace.read_text().splitlines() if trace.exists() else []
        fail_bin = work / "failing-node-bin"
        fail_bin.mkdir()
        real_node = str(node)
        wrapper = fail_bin / "node"
        write_executable(
            wrapper,
            "#!/bin/sh\n"
            'case "$*" in\n'
            '  *"dev-loop.mjs build"*) echo "forced build failure" >&2; exit 42 ;;\n'
            f'  *) exec "{real_node}" "$@" ;;\n'
            'esac\n',
        )
        failing_path = f"{fail_bin}:{search_path}"
        if require_tool("node", failing_path) != wrapper.resolve(strict=True):
            raise RuntimeError("Build-failure test would not use its proved node wrapper")
        validate_mocks(mock_bin, failing_path)
        failed = run_setup(home, failing_path, trace, check=False)
        if failed.returncode == 0 or "forced build failure" not in failed.stderr:
            raise AssertionError(f"build failure was not reported:\n{failed.stdout}\n{failed.stderr}")
        if target.readlink() != old_link:
            raise AssertionError("failed build replaced the last-good development link")
        after_stow_calls = trace.read_text().splitlines() if trace.exists() else []
        if after_stow_calls != before_stow_calls:
            raise AssertionError("stow ran after the failed build")
        if forbidden_trace.exists():
            raise AssertionError(f"native/Nix command was invoked: {forbidden_trace.read_text()}")

    print("Herdr bootstrap passed in disposable homes; no native command or live app home was used.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
