"""Exercise managed config links with isolated homes and no native commands."""
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
        self.source = self.root / "source"
        for path, content in {
            "keys.json": "managed keys\n",
            "layouts/tmux.json": "managed layout\n",
            "themes/personal.json": "managed theme\n",
            "data/muxcle-sessionizer/config.json": "managed discovery roots\n",
        }.items():
            target = self.source / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content)
        self.home = self.root / "home"
        self.app = self.home / ".config/herdr-app"
        self.app.mkdir(parents=True)
        patches = ExitStack()
        self.addCleanup(patches.close)
        patches.enter_context(mock.patch.object(installer, "SOURCE_ROOT", self.source))
        patches.enter_context(mock.patch.object(installer, "read_dev_mods", return_value=[]))
        patches.enter_context(mock.patch.object(installer, "read_native_views", return_value={}))
        patches.enter_context(mock.patch.object(installer, "select_generations", return_value={}))
        patches.enter_context(mock.patch.object(installer, "command_path", side_effect=AssertionError("Native command forbidden")))

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

        for _ in range(2):
            self.assertIsNone(installer.install(self.home))
            for relative, content in preserved.items():
                self.assertEqual((self.app / relative).read_text(), content)
            for relative in ("mods", "data", "data/muxcle-sessionizer", "layouts", "themes"):
                self.assertTrue((self.app / relative).is_dir())
                self.assertFalse((self.app / relative).is_symlink())
            for relative in ("keys.json", "layouts/tmux.json", "data/muxcle-sessionizer/config.json"):
                self.assertEqual((self.app / relative).resolve(), self.source / relative)

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

    def test_broken_managed_link_is_preserved_before_replacement(self):
        missing = self.root / "missing"
        keys = self.app / "keys.json"
        keys.symlink_to(missing)

        backup = installer.install(self.home)

        self.assertEqual((backup / "keys.json").readlink(), missing)
        self.assertFalse(missing.exists())
        self.assertEqual(keys.resolve(), self.source / "keys.json")

    def test_linked_mutable_container_refuses_before_changing_any_files(self):
        foreign = self.root / "foreign"
        foreign.mkdir()
        (foreign / "keep").write_text("untouched\n")
        (self.app / "keys.json").write_text("original keys\n")
        for name in ("mods", "data", "layouts", "themes"):
            with self.subTest(container=name):
                link = self.app / name
                link.symlink_to(foreign, target_is_directory=True)
                try:
                    with self.assertRaisesRegex(ValueError, "linked container"):
                        installer.install(self.home)
                    self.assertEqual((self.app / "keys.json").read_text(), "original keys\n")
                    self.assertEqual((foreign / "keep").read_text(), "untouched\n")
                    self.assertEqual(sorted(path.name for path in foreign.iterdir()), ["keep"])
                    self.assertEqual(list((self.home / ".config").glob("herdr-app.backup.*")), [])
                finally:
                    link.unlink()
