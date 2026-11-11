import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
BASH = Path("/bin/bash").resolve()
INSTALL_SPEC = importlib.util.spec_from_file_location(
    "herdr_install", ROOT / "stow/herdr/install.py"
)
HERDR_INSTALL = importlib.util.module_from_spec(INSTALL_SPEC)
INSTALL_SPEC.loader.exec_module(HERDR_INSTALL)


class ControlledCommands:
    def __init__(self, parent):
        self.directory = parent / "mock-bin"
        self.directory.mkdir()
        self.trace = parent / "commands.log"
        self.environment = os.environ.copy()
        self.environment.update({
            "HOME": str(parent / "home"),
            "COMMAND_TRACE": str(self.trace),
            "PATH": f"{self.directory}:/usr/bin:/bin",
        })
        Path(self.environment["HOME"]).mkdir()

    def add(self, name, body):
        path = self.directory / name
        path.write_text(f"#!/bin/sh\nset -eu\n{body}\n")
        path.chmod(0o755)
        resolved = path.resolve(strict=True)
        if resolved.parent != self.directory.resolve():
            raise AssertionError(f"mock {name} escaped the controlled command directory: {resolved}")
        return path

    def assert_mock_resolves(self, name):
        resolved = Path(shutil.which(name, path=self.environment["PATH"])).resolve(strict=True)
        if resolved.parent != self.directory.resolve():
            raise AssertionError(f"{name} would not resolve to the proved mock: {resolved}")
        return resolved

    def entries(self):
        if not self.trace.exists():
            return []
        return self.trace.read_text().splitlines()

    def guard_commands(self, names):
        for name in names:
            self.add(name, f'printf "forbidden:{name}\\n" >> "$COMMAND_TRACE"; exit 97')
            self.assert_mock_resolves(name)


class InstallerPolicyTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="dotfiles-herdr-policy-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.source = self.root / "stow/herdr/.config/herdr-app"
        (self.source / "mods").mkdir(parents=True)

    def test_selection_accepts_comments_and_validates_names_and_duplicates(self):
        selection = self.root / "dev-mods.txt"
        selection.write_text("# enabled mods\nmuxcle-picker\n\nmuxcle-history # optional\n")
        with mock.patch.object(HERDR_INSTALL, "SOURCE_ROOT", self.source):
            self.assertEqual(
                HERDR_INSTALL.read_dev_mods(selection),
                ["muxcle-picker", "muxcle-history"],
            )
            selection.write_text("muxcle-picker\nmuxcle-picker\n")
            with self.assertRaisesRegex(ValueError, "Duplicate Herdr mod"):
                HERDR_INSTALL.read_dev_mods(selection)
            selection.write_text("../outside\n")
            with self.assertRaisesRegex(ValueError, "Invalid Herdr mod name"):
                HERDR_INSTALL.read_dev_mods(selection)

    def test_selection_refuses_names_owned_by_the_existing_stow_tree(self):
        selection = self.root / "dev-mods.txt"
        selection.write_text("tmux-picker\n")
        (self.source / "mods/tmux-picker").symlink_to(self.root / "legacy-picker")
        with mock.patch.object(HERDR_INSTALL, "SOURCE_ROOT", self.source):
            with self.assertRaisesRegex(ValueError, "already owned by the Stow"):
                HERDR_INSTALL.read_dev_mods(selection)

    def test_generation_validation_checks_ownership_and_complete_payload(self):
        child = self.root / "herdr-term"
        generation_root = child / ".build/dev-generations/project-id/muxcle-picker-test-generation"
        home = generation_root / "home"
        mod = home / "mods/muxcle-picker"
        mod.mkdir(parents=True)
        managed_root = child / ".build/dev-generations"
        (managed_root / ".muxcle-dev-loop.json").write_text(
            json.dumps({"schema": 1, "projectId": "project"})
        )
        (generation_root / ".muxcle-dev-generation.json").write_text(
            json.dumps({
                "schema": 1,
                "projectId": "project",
                "id": "muxcle-picker-test-generation",
                "modName": "muxcle-picker",
            })
        )
        (mod / "mod.json").write_text("{}\n")
        (mod / "main.js").write_text("export {};\n")
        (mod / "package-owner.json").write_text(
            json.dumps({"package": "muxcle-picker", "schema": 1})
        )
        output = f"Built muxcle-picker generation muxcle-picker-test-generation\n{home}\n"

        with mock.patch.object(HERDR_INSTALL, "SUBMODULE", child):
            self.assertEqual(
                HERDR_INSTALL.validate_generation("muxcle-picker", output),
                "muxcle-picker-test-generation",
            )
            (mod / "main.js").unlink()
            with self.assertRaisesRegex(RuntimeError, "output is incomplete"):
                HERDR_INSTALL.validate_generation("muxcle-picker", output)


class PinnedSubmoduleTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="dotfiles-herdr-submodule-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.submodule = self.root / "herdr-term"
        self.dev_loop = self.submodule / "scripts/dev-loop.mjs"
        self.pin = "a" * 40

    def test_uninitialized_child_updates_only_to_the_parent_gitlink(self):
        commands = []

        def run(command, **_kwargs):
            commands.append(command)
            if "submodule" in command:
                (self.submodule / "scripts").mkdir(parents=True)
                (self.submodule / ".git").write_text("gitdir: ../.git/modules/herdr-term\n")
                self.dev_loop.write_text("// test fixture\n")
                return ""
            return self.pin

        with mock.patch.object(HERDR_INSTALL, "DOTFILES_ROOT", self.root), \
             mock.patch.object(HERDR_INSTALL, "SUBMODULE", self.submodule), \
             mock.patch.object(HERDR_INSTALL, "DEV_LOOP", self.dev_loop), \
             mock.patch.object(HERDR_INSTALL, "command_path", return_value="/test/git"), \
             mock.patch.object(HERDR_INSTALL, "run_checked", side_effect=run):
            HERDR_INSTALL.ensure_pinned_submodule()

        update = next(command for command in commands if "submodule" in command)
        self.assertEqual(update[-5:], ["update", "--init", "--recursive", "--", "herdr-term"])
        self.assertNotIn("--remote", update)
        self.assertEqual(commands[-1][-2:], ["rev-parse", "HEAD"])

    def test_initialized_child_at_another_commit_is_refused_without_checkout(self):
        self.submodule.mkdir()
        (self.submodule / ".git").write_text("gitdir: ../.git/modules/herdr-term\n")
        commands = []
        values = iter((self.pin, "b" * 40))

        def run(command, **_kwargs):
            commands.append(command)
            return next(values)

        with mock.patch.object(HERDR_INSTALL, "DOTFILES_ROOT", self.root), \
             mock.patch.object(HERDR_INSTALL, "SUBMODULE", self.submodule), \
             mock.patch.object(HERDR_INSTALL, "DEV_LOOP", self.dev_loop), \
             mock.patch.object(HERDR_INSTALL, "command_path", return_value="/test/git"), \
             mock.patch.object(HERDR_INSTALL, "run_checked", side_effect=run):
            with self.assertRaisesRegex(RuntimeError, "differs from the dotfiles pin"):
                HERDR_INSTALL.ensure_pinned_submodule()

        self.assertEqual(len(commands), 2)
        self.assertFalse(any("submodule" in command for command in commands))


class InstallerEntryTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="dotfiles-herdr-test-")
        self.addCleanup(self.temporary.cleanup)
        self.parent = Path(self.temporary.name)
        self.commands = ControlledCommands(self.parent)
        self.commands.guard_commands(("git", "npm", "node", "nix", "herdr-app", "hc"))

    def run_install(self, *arguments):
        return subprocess.run(
            [str(BASH), str(ROOT / "install.sh"), *arguments],
            env=self.commands.environment,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_osx_installer_clones_recursive_submodules_and_dispatches_osx(self):
        self.commands.add(
            "nix-shell",
            'printf "nix-shell" >> "$COMMAND_TRACE"; for arg do printf "|%s" "$arg" >> "$COMMAND_TRACE"; done; printf "\\n" >> "$COMMAND_TRACE"',
        )
        self.commands.assert_mock_resolves("nix-shell")
        self.prepare_fixture_setup_scripts()

        result = self.run_install("osx")

        self.assertEqual(result.returncode, 0, result.stderr)
        call = self.commands.entries()[0]
        self.assertIn("--recurse-submodules", call)
        self.assertIn("git clone", call)
        self.assertEqual(self.setup_calls(), ["osx"])

    def test_linux_installer_dispatches_only_linux_setup(self):
        self.commands.add(
            "nix-shell",
            'printf "nix-shell" >> "$COMMAND_TRACE"; for arg do printf "|%s" "$arg" >> "$COMMAND_TRACE"; done; printf "\\n" >> "$COMMAND_TRACE"',
        )
        self.commands.assert_mock_resolves("nix-shell")
        self.prepare_fixture_setup_scripts()

        result = self.run_install("linux")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.setup_calls(), ["linux"])

    def test_missing_or_unsupported_os_fails_before_invoking_nix(self):
        self.commands.add("nix-shell", 'printf "unexpected" >> "$COMMAND_TRACE"')
        self.commands.assert_mock_resolves("nix-shell")

        for arguments in [(), ("windows",), ("linux", "extra")]:

            result = self.run_install(*arguments)
            self.assertEqual(result.returncode, 2, result.stderr)
            self.assertIn("Usage:", result.stderr)
        self.assertEqual(self.commands.entries(), [])

    def prepare_fixture_setup_scripts(self):
        home_dotfiles = Path(self.commands.environment["HOME"]) / ".dotfiles"
        for system in ("osx", "nixos"):
            setup = home_dotfiles / "nix" / system / "setup.sh"
            setup.parent.mkdir(parents=True, exist_ok=True)
            label = "linux" if system == "nixos" else system
            setup.write_text(
                f'#!/bin/sh\nprintf "{label}\\n" >> "$SETUP_TRACE"\n'
            )
            setup.chmod(0o755)
        self.commands.environment["SETUP_TRACE"] = str(self.parent / "setup.log")

    def setup_calls(self):
        path = Path(self.commands.environment["SETUP_TRACE"])
        return path.read_text().splitlines() if path.exists() else []


class StowPreflightOrderingTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="dotfiles-herdr-stow-test-")
        self.addCleanup(self.temporary.cleanup)
        self.parent = Path(self.temporary.name)
        self.commands = ControlledCommands(self.parent)
        self.commands.guard_commands(("git", "npm", "node", "nix", "nix-shell", "herdr-app", "hc"))
        home_dotfiles = Path(self.commands.environment["HOME"]) / ".dotfiles"
        (home_dotfiles / "stow").mkdir(parents=True)
        shutil.copy2(ROOT / "stow/common.sh", home_dotfiles / "stow/common.sh")
        self.commands.environment["COMMAND_TRACE"] = str(self.commands.trace)
        self.commands.add(
            "python3",
            'printf "python3" >> "$COMMAND_TRACE"; for arg do printf "|%s" "$arg" >> "$COMMAND_TRACE"; done; printf "\\n" >> "$COMMAND_TRACE"',
        )
        self.commands.add("stow", 'printf "stow" >> "$COMMAND_TRACE"; printf "\\n" >> "$COMMAND_TRACE"')
        self.commands.add("bash", f'exec "{BASH}" "$@"')
        self.commands.add("uname", 'printf "Darwin\\n"')
        for name in ("python3", "stow", "bash", "uname"):
            self.commands.assert_mock_resolves(name)

    def test_herdr_prepare_precedes_stow_mutation(self):
        result = subprocess.run(
            [str(BASH), str(ROOT / "stow/install.sh"), "herdr"],
            cwd=ROOT,
            env=self.commands.environment,
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        events = self.commands.entries()
        prepare = next(i for i, event in enumerate(events) if "--prepare" in event)
        install = next(i for i, event in enumerate(events) if "install.py" in event and "--prepare" not in event)
        stow = next(i for i, event in enumerate(events) if event == "stow")
        self.assertLess(prepare, install)
        self.assertLess(install, stow)


if __name__ == "__main__":
    unittest.main()
