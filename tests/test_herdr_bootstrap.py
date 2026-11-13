import importlib.util
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("herdr_install", ROOT / "stow/herdr/install.py")
installer = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(installer)


class CommandTimeoutTests(unittest.TestCase):
    def test_git_timeout_is_bounded_and_reported_clearly(self):
        command = ["/test/git", "submodule", "update"]
        with mock.patch.object(
            installer.subprocess,
            "run",
            side_effect=subprocess.TimeoutExpired(command, 300),
        ) as run:
            with self.assertRaisesRegex(RuntimeError, "Command timed out after 300s"):
                installer.run_checked(command)

        run.assert_called_once_with(
            command, text=True, capture_output=True, check=False, timeout=300
        )


class PinnedSourceTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="herdr-pin-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.submodule = self.root / "herdr-term"
        self.source_tree = self.submodule / "herdr"
        self.pin = "a" * 40

    def run_pinned_check(self, responses):
        commands = []

        def run(command, **_kwargs):
            commands.append(command)
            result = responses(command)
            return result

        with mock.patch.object(installer, "DOTFILES_ROOT", self.root), \
             mock.patch.object(installer, "SUBMODULE", self.submodule), \
             mock.patch.object(installer, "SOURCE_TREE", self.source_tree), \
             mock.patch.object(installer, "command_path", return_value="/test/git"), \
             mock.patch.object(installer, "run_checked", side_effect=run):
            installer.ensure_pinned_submodule()
        return commands

    def test_uninitialized_submodule_is_initialized_at_exact_parent_pin(self):
        def run(command):
            if command[-2:] == ["rev-parse", "HEAD:herdr-term"]:
                return self.pin
            if "submodule" in command:
                self.source_tree.mkdir(parents=True)
                (self.submodule / ".git").write_text("gitdir: ../modules/herdr-term\n")
                return ""
            if command[-2:] == ["rev-parse", "HEAD"]:
                return self.pin
            self.fail(f"Unexpected Git command: {command}")

        commands = self.run_pinned_check(run)

        self.assertEqual(commands[0][-2:], ["rev-parse", "HEAD:herdr-term"])
        self.assertEqual(
            commands[1][-5:],
            ["update", "--init", "--recursive", "--", "herdr-term"],
        )
        self.assertNotIn("--remote", commands[1])
        self.assertEqual(commands[2][-2:], ["rev-parse", "HEAD"])

    def test_initialized_submodule_at_different_commit_is_refused_without_checkout(self):
        self.submodule.mkdir()
        (self.submodule / ".git").write_text("gitdir: ../modules/herdr-term\n")
        self.source_tree.mkdir()
        commands = []
        results = iter((self.pin, "b" * 40))

        def run(command, **_kwargs):
            commands.append(command)
            return next(results)

        with mock.patch.multiple(
            installer,
            DOTFILES_ROOT=self.root,
            SUBMODULE=self.submodule,
            SOURCE_TREE=self.source_tree,
            command_path=mock.Mock(return_value="/test/git"),
            run_checked=mock.Mock(side_effect=run),
        ):
            with self.assertRaisesRegex(RuntimeError, "differs from the dotfiles pin"):
                installer.ensure_pinned_submodule()

        self.assertEqual(len(commands), 2)
        self.assertFalse(any("submodule" in command for command in commands))

    def test_missing_herdr_source_tree_is_refused(self):
        self.submodule.mkdir()
        (self.submodule / ".git").write_text("gitdir: ../modules/herdr-term\n")

        with mock.patch.object(installer, "DOTFILES_ROOT", self.root), \
             mock.patch.object(installer, "SUBMODULE", self.submodule), \
             mock.patch.object(installer, "SOURCE_TREE", self.source_tree), \
             mock.patch.object(installer, "command_path", return_value="/test/git"), \
             mock.patch.object(installer, "run_checked", side_effect=(self.pin, self.pin)):
            with self.assertRaisesRegex(RuntimeError, "herdr source tree is missing"):
                installer.ensure_pinned_submodule()


class DirectSourceInstallTests(unittest.TestCase):
    def test_install_uses_only_git_and_links_mod_directory_from_submodule_source(self):
        with tempfile.TemporaryDirectory(prefix="herdr-direct-") as temporary:
            root = Path(temporary)
            submodule = root / "herdr-term"
            submodule.mkdir()
            (submodule / ".git").write_text("gitdir: ../modules/herdr-term\n")
            mod = submodule / "herdr/mods/sample-mod"
            mod.mkdir(parents=True)
            (mod / "main.js").write_text("export {};\n")

            source = root / "stow/herdr/.config/herdr-app"
            (source / "mods").mkdir(parents=True)
            (source / "mods/sample-mod").symlink_to(mod, target_is_directory=True)
            (source / "keys.json").write_text("{}\n")
            home = root / "home"
            home.mkdir()
            trace = root / "git.log"
            bin_dir = root / "bin"
            bin_dir.mkdir()
            git = bin_dir / "git"
            pin = "a" * 40
            git.write_text(
                "#!/bin/sh\n"
                f"printf '%s\\n' \"$*\" >> {shlex.quote(str(trace))}\n"
                "case \"$*\" in\n"
                f"  *{shlex.quote(str(root) + ' rev-parse HEAD:herdr-term')}*) printf '%s\\n' '{pin}' ;;\n"
                f"  *{shlex.quote(str(submodule) + ' rev-parse HEAD')}*) printf '%s\\n' '{pin}' ;;\n"
                "  *) exit 91 ;;\n"
                "esac\n"
            )
            git.chmod(0o755)
            environment = {
                "HOME": str(home),
                "PATH": str(bin_dir),
                "HERDR_PREPARED": "false",
            }

            with mock.patch.object(installer, "DOTFILES_ROOT", root), \
                 mock.patch.object(installer, "SUBMODULE", submodule), \
                 mock.patch.object(installer, "SOURCE_TREE", submodule / "herdr"), \
                 mock.patch.object(installer, "SOURCE_ROOT", source), \
                 mock.patch.dict(os.environ, environment, clear=True), \
                 mock.patch.object(installer.sys, "argv", ["install.py"]):
                self.assertEqual(installer.main(), 0)

            app = home / ".config/herdr-app"
            installed_mod = app / "mods/sample-mod"
            self.assertTrue(installed_mod.is_symlink())
            self.assertEqual(installed_mod.resolve(), mod.resolve())
            self.assertEqual((installed_mod / "main.js").read_text(), "export {};\n")
            self.assertEqual((app / "keys.json").resolve(), (source / "keys.json").resolve())
            self.assertTrue((app / "mods").is_dir())
            self.assertFalse((app / "mods").is_symlink())
            self.assertEqual(len(trace.read_text().splitlines()), 2)

    def test_prepare_flag_validates_source_without_installing(self):
        with tempfile.TemporaryDirectory(prefix="herdr-prepare-") as temporary:
            home = Path(temporary)
            with mock.patch.dict(os.environ, {"HOME": str(home)}, clear=False):
                with mock.patch.object(installer.sys, "argv", ["install.py", "--prepare"]):
                    with mock.patch.object(installer, "ensure_pinned_submodule") as ensure:
                        with mock.patch.object(installer, "install") as install:
                            self.assertEqual(installer.main(), 0)
            ensure.assert_called_once_with()
            install.assert_not_called()

    def test_parent_prepared_flag_skips_only_repeated_pin_check(self):
        with tempfile.TemporaryDirectory(prefix="herdr-prepared-") as temporary:
            home = Path(temporary)
            with mock.patch.dict(
                os.environ, {"HOME": str(home), "HERDR_PREPARED": "true"}, clear=False
            ):
                with mock.patch.object(installer.sys, "argv", ["install.py"]):
                    with mock.patch.object(installer, "ensure_pinned_submodule") as ensure:
                        with mock.patch.object(installer, "install") as install:
                            self.assertEqual(installer.main(), 0)
            ensure.assert_not_called()
            install.assert_called_once_with(home)


class ParentStowPreparationTests(unittest.TestCase):
    def test_parent_prepare_delegates_once_and_exports_prepared_flag(self):
        with tempfile.TemporaryDirectory(prefix="herdr-parent-stow-") as temporary:
            root = Path(temporary)
            home = root / "home"
            home.mkdir()
            (home / ".dotfiles").symlink_to(ROOT, target_is_directory=True)
            mock_bin = root / "mock-bin"
            safe_bin = root / "safe-bin"
            mock_bin.mkdir()
            safe_bin.mkdir()
            trace = root / "commands.log"

            tools = {
                "bash": f'#!/bin/sh\nexec {shlex.quote(str(Path("/bin/bash").resolve()))} "$@"\n',
                "python3": 'printf "python3|%s|%s\n" "$*" "${HERDR_PREPARED-}" >> "$COMMAND_TRACE"\n',
                "stow": 'printf "stow|%s\n" "$*" >> "$COMMAND_TRACE"\n',
                "uname": 'printf "Darwin\n"\n',
            }
            for name, body in tools.items():
                command = mock_bin / name
                command.write_text(f"#!/bin/sh\n{body}")
                command.chmod(0o755)
            for name in ("ls", "basename"):
                found = shutil.which(name, path=os.defpath)
                self.assertIsNotNone(found, f"missing safe test utility: {name}")
                (safe_bin / name).symlink_to(Path(found).resolve(strict=True))

            environment = {
                "HOME": str(home),
                "PATH": f"{mock_bin}:{safe_bin}",
                "COMMAND_TRACE": str(trace),
            }
            result = subprocess.run(
                [str(Path("/bin/bash").resolve()), str(ROOT / "stow/install.sh"), "herdr"],
                cwd=ROOT,
                env=environment,
                text=True,
                capture_output=True,
                check=False,
                timeout=20,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            events = trace.read_text().splitlines()
            python_events = [index for index, event in enumerate(events) if event.startswith("python3|")]
            stow_events = [index for index, event in enumerate(events) if event.startswith("stow|")]
            self.assertEqual(len(python_events), 2)
            self.assertIn("--prepare", events[python_events[0]])
            self.assertNotIn("--prepare", events[python_events[1]])
            self.assertIn("|true", events[python_events[1]])
            self.assertEqual(len(stow_events), 1)
            self.assertLess(python_events[1], stow_events[0])


if __name__ == "__main__":
    unittest.main()
