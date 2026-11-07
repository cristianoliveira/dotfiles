"""Exercise the Herdr Stow package without touching the user's home."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[4]
PACKAGE = ROOT / "stow/herdr"


@unittest.skipUnless(shutil.which("stow"), "GNU Stow is required")
class InstallTests(unittest.TestCase):
    def test_install_and_restow_preserve_runtime_state_and_link_theme(self):
        for existing in (False, True):
            with self.subTest(existing=existing), tempfile.TemporaryDirectory() as directory:
                home = Path(directory)
                app = home / ".config/herdr-app"
                app.mkdir(parents=True)
                settings = app / "settings.json"
                settings.write_text('{"zoom": 1.25}\n')
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
                    if existing:
                        self.assertEqual((app / "themes/personal.json").read_text(), "{}\n")


if __name__ == "__main__":
    unittest.main()
