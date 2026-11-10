"""Exercise the Herdr Stow package without touching the user's home."""

import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[4]
PACKAGE = ROOT / "stow/herdr"


@unittest.skipUnless(shutil.which("stow"), "GNU Stow is required")
class InstallTests(unittest.TestCase):
    def test_conflicting_managed_paths_are_backed_up_and_replaced(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            app = home / ".config/herdr-app"
            (app / "mods/project-picker").mkdir(parents=True)
            (app / "mods/project-picker/custom.txt").write_text("old mod")
            (app / "themes").mkdir()
            (app / "keys.json").write_text("old keys")
            (app / "themes/solarized-dark.json").write_text("old theme")
            (app / "settings.json").write_text("personal settings")
            (app / "mods/personal").mkdir()
            (app / "mods/personal/note").write_text("unmanaged")
            external = home / "external-layout.json"
            external.write_text("external layout")
            (app / "layouts").mkdir()
            (app / "layouts/tmux.json").symlink_to(external)
            env = {**os.environ, "HOME": str(home)}

            for option in ("--stow", "--restow"):
                subprocess.run(["bash", str(PACKAGE / "before_install.sh")], env=env, check=True, capture_output=True)
                subprocess.run(["stow", "--dir", str(ROOT / "stow"), "--target", str(home), option, "herdr"],
                               check=True, capture_output=True)

            self.assertEqual((app / "keys.json").resolve(), ROOT / "nix/shared/herdr/keys.json")
            self.assertEqual((app / "mods/project-picker").resolve(), ROOT / "nix/shared/herdr/mods/project-picker")
            self.assertEqual((app / "mods/image-preview").resolve(), ROOT / "nix/shared/herdr/mods/image-preview")
            self.assertEqual((app / "mods/port-forward").resolve(), ROOT / "nix/shared/herdr/mods/port-forward")
            self.assertEqual((app / "themes/solarized-dark.json").resolve(), ROOT / "nix/shared/herdr/themes/solarized-dark.json")
            self.assertEqual((app / "layouts/tmux.json").resolve(), ROOT / "nix/shared/herdr/layouts/tmux.json")
            self.assertEqual((app / "settings.json").read_text(), "personal settings")
            self.assertEqual((app / "mods/personal/note").read_text(), "unmanaged")
            self.assertEqual(external.read_text(), "external layout")
            backups = list((home / ".config").glob("herdr-app.backup.*"))
            self.assertEqual(len(backups), 1)
            self.assertEqual((backups[0] / "keys.json").read_text(), "old keys")
            self.assertEqual((backups[0] / "mods/project-picker/custom.txt").read_text(), "old mod")
            self.assertEqual((backups[0] / "themes/solarized-dark.json").read_text(), "old theme")
            self.assertTrue((backups[0] / "layouts/tmux.json").is_symlink())
            self.assertFalse((home / "install.py").exists())
            self.assertFalse((home / "__pycache__").exists())

    def test_keys_replacement_has_no_missing_file_window(self):
        spec = importlib.util.spec_from_file_location("herdr_install", PACKAGE / "install.py")
        installer = importlib.util.module_from_spec(spec)
        with patch.object(sys, "dont_write_bytecode", True):
            spec.loader.exec_module(installer)
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory) / "home's 日本語"
            app = home / ".config/herdr-app"
            app.mkdir(parents=True)
            keys = app / "keys.json"
            keys.write_text("original keys")
            replace = os.replace
            checked = []

            def checked_replace(source, target):
                if target == keys.resolve():
                    self.assertTrue(keys.is_file())
                    self.assertFalse(keys.is_symlink())
                    self.assertEqual(keys.read_text(), "original keys")
                    checked.append(True)
                replace(source, target)

            with patch.object(installer.os, "replace", side_effect=checked_replace):
                backup = installer.install(home)

            self.assertEqual(checked, [True])
            self.assertEqual((backup / "keys.json").read_text(), "original keys")
            self.assertEqual(keys.resolve(), ROOT / "nix/shared/herdr/keys.json")

    def test_broken_managed_link_is_preserved_and_replaced(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            app = home / ".config/herdr-app"
            app.mkdir(parents=True)
            missing = home / "missing"
            (app / "keys.json").symlink_to(missing)

            subprocess.run(["bash", str(PACKAGE / "before_install.sh")],
                           env={**os.environ, "HOME": str(home)}, check=True, capture_output=True)

            backup = next((home / ".config").glob("herdr-app.backup.*"))
            self.assertEqual(os.readlink(backup / "keys.json"), str(missing))
            self.assertFalse(missing.exists())
            self.assertEqual((app / "keys.json").resolve(), ROOT / "nix/shared/herdr/keys.json")

    def test_linked_mutable_container_is_refused_without_changing_external_files(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            app = home / ".config/herdr-app"
            app.mkdir(parents=True)
            external = home / "external"
            external.mkdir()
            (external / "personal").write_text("untouched")
            (app / "mods").symlink_to(external, target_is_directory=True)
            (app / "keys.json").write_text("original keys")

            result = subprocess.run(["bash", str(PACKAGE / "before_install.sh")],
                                    env={**os.environ, "HOME": str(home)}, capture_output=True)

            self.assertNotEqual(result.returncode, 0)
            self.assertEqual((external / "personal").read_text(), "untouched")
            self.assertEqual(list(external.iterdir()), [external / "personal"])
            self.assertEqual((app / "keys.json").read_text(), "original keys")

    def test_install_and_restow_preserve_runtime_state_and_link_theme(self):
        for existing in (False, True):
            with self.subTest(existing=existing), tempfile.TemporaryDirectory() as directory:
                home = Path(directory)
                app = home / ".config/herdr-app"
                app.mkdir(parents=True)
                settings = app / "settings.json"
                settings.write_text('{"zoom": 1.25}\n')
                (app / "data").mkdir()
                (app / "data/session.json").write_text("session state")
                (app / "view.json").write_text("view state")
                if existing:
                    (app / "themes").mkdir()
                    (app / "themes/personal.json").write_text("{}\n")

                for option in ("--stow", "--restow"):
                    subprocess.run(
                        ["bash", str(PACKAGE / "before_install.sh")],
                        env={**os.environ, "HOME": str(home)},
                        check=True,
                    )
                    subprocess.run(
                        ["stow", "--dir", str(ROOT / "stow"), "--target", str(home), option, "herdr"],
                        check=True,
                        capture_output=True,
                    )

                    theme = app / "themes/solarized-dark.json"
                    self.assertTrue(theme.is_file())
                    self.assertEqual(theme.resolve(), ROOT / "nix/shared/herdr/themes/solarized-dark.json")
                    self.assertFalse((app / "themes").is_symlink())
                    self.assertEqual(settings.read_text(), '{"zoom": 1.25}\n')
                    self.assertEqual((app / "data/session.json").read_text(), "session state")
                    self.assertEqual((app / "view.json").read_text(), "view state")
                    self.assertEqual(list((home / ".config").glob("herdr-app.backup.*")), [])
                    self.assertFalse((home / "__pycache__").exists())
                    if existing:
                        self.assertEqual((app / "themes/personal.json").read_text(), "{}\n")


if __name__ == "__main__":
    unittest.main()
