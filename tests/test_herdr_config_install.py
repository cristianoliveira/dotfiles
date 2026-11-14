"""Exercise source links with isolated homes and preserve unrelated runtime state."""
import importlib.util
import os
from contextlib import ExitStack
from pathlib import Path
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("herdr_config_install", ROOT / "stow/herdr/install.py")
installer = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(installer)


class ConfigInstallTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="herdr-config-install-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        self.source = self.root / "stow/herdr/.config/herdr-app"
        for path, content in {
            "keys.json": "managed keys\n",
            "layouts/tmux.json": "managed layout\n",
            "themes/personal.json": "managed theme\n",
        }.items():
            target = self.source / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content)

        self.submodule_source = self.root / "herdr-term"
        self.mod = self.submodule_source / "mods/sample-mod"
        self.mod.mkdir(parents=True)
        (self.mod / "main.js").write_text("export {};\n")
        (self.mod / "mod.json").write_text('{"name":"sample-mod"}\n')
        (self.source / "mods").mkdir()
        (self.source / "mods/sample-mod").symlink_to(self.mod, target_is_directory=True)

        self.home = self.root / "home"
        self.app = self.home / ".config/herdr-app"
        self.app.mkdir(parents=True)
        patches = ExitStack()
        self.addCleanup(patches.close)
        patches.enter_context(mock.patch.object(installer, "SOURCE_ROOT", self.source))

    def test_links_each_mod_as_one_directory_and_keeps_mutable_containers_real(self):
        self.assertIsNone(installer.install(self.home))

        installed_mod = self.app / "mods/sample-mod"
        self.assertTrue(installed_mod.is_symlink())
        self.assertEqual(installed_mod.resolve(), self.mod.resolve())
        self.assertEqual((installed_mod / "main.js").read_text(), "export {};\n")
        for relative in (".", "mods", "data"):
            container = self.app if relative == "." else self.app / relative
            self.assertTrue(container.is_dir())
            self.assertFalse(container.is_symlink())

    def test_repeat_install_preserves_runtime_state_and_real_mutable_containers(self):
        (self.app / "data").mkdir()
        (self.app / "mods/personal").mkdir(parents=True)
        preserved = {
            "settings.json": "personal settings\n",
            "shared.json": "personal shared state\n",
            "view.json": "personal view state\n",
            "data/session.json": "session state\n",
            "mods/personal/main.js": "personal mod\n",
        }
        for relative, content in preserved.items():
            (self.app / relative).write_text(content)

        installed_mod = self.app / "mods/sample-mod"
        for _ in range(2):
            self.assertIsNone(installer.install(self.home))
            for relative, content in preserved.items():
                self.assertEqual((self.app / relative).read_text(), content)
            for relative in ("mods", "data", "layouts", "themes"):
                container = self.app / relative
                self.assertTrue(container.is_dir())
                self.assertFalse(container.is_symlink())
            for relative in (
                "keys.json",
                "layouts/tmux.json",
            ):
                self.assertEqual((self.app / relative).resolve(), self.source / relative)
            self.assertEqual(installed_mod.resolve(), self.mod.resolve())

    def test_conflicting_keys_are_backed_up_without_a_missing_file_window(self):
        keys = self.app / "keys.json"
        keys.write_text("original keys\n")
        replace = os.replace
        observed = []

        def checked_replace(source, destination):
            if destination == keys:
                self.assertEqual(keys.read_text(), "original keys\n")
                observed.append(True)
            replace(source, destination)

        with mock.patch.object(installer.os, "replace", side_effect=checked_replace):
            backup = installer.install(self.home)

        self.assertEqual(observed, [True])
        self.assertEqual((backup / "keys.json").read_text(), "original keys\n")
        self.assertEqual(keys.read_text(), "managed keys\n")

    def test_conflicting_directory_and_symlink_are_preserved_in_backup(self):
        layout = self.app / "layouts/tmux.json"
        missing = self.root / "missing-layout"
        layout.parent.mkdir()
        layout.symlink_to(missing)
        theme = self.app / "themes/personal.json"
        theme.mkdir(parents=True)
        (theme / "personal.json").write_text("keep directory\n")

        backup = installer.install(self.home)

        self.assertEqual((backup / "layouts/tmux.json").readlink(), missing)
        self.assertEqual((backup / "themes/personal.json/personal.json").read_text(), "keep directory\n")
        self.assertEqual(layout.resolve(), self.source / "layouts/tmux.json")
        self.assertEqual(theme.resolve(), self.source / "themes/personal.json")

    def test_linked_app_mod_or_data_container_refuses_before_changes(self):
        for container in ("app", "mods", "data"):
            with self.subTest(container=container):
                foreign = self.root / f"foreign-{container}"
                foreign.mkdir(exist_ok=True)
                marker = foreign / "keep"
                marker.write_text("untouched\n")
                target = self.app if container == "app" else self.app / container
                if target == self.app:
                    target.rmdir()
                elif target.exists():
                    target.rmdir()
                target.symlink_to(foreign, target_is_directory=True)
                try:
                    with self.assertRaisesRegex(ValueError, "linked container"):
                        installer.install(self.home)
                    self.assertEqual(marker.read_text(), "untouched\n")
                    self.assertEqual(sorted(path.name for path in foreign.iterdir()), ["keep"])
                    self.assertFalse((self.app / "keys.json").exists())
                    self.assertEqual(list((self.home / ".config").glob("herdr-app.backup.*")), [])
                finally:
                    target.unlink()
                    if target == self.app:
                        self.app.mkdir()


if __name__ == "__main__":
    unittest.main()
