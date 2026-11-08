"""Check Brave tab navigation without opening or changing browser windows."""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "brave-tabs.applescript"


@unittest.skipUnless(sys.platform == "darwin", "AppleScript requires macOS")
class BraveTabsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        cls.addClassCleanup(cls.directory.cleanup)
        cls.compiled = Path(cls.directory.name) / "brave-tabs.scpt"
        subprocess.run(
            ["/usr/bin/osacompile", "-o", str(cls.compiled), str(SCRIPT)],
            check=True, capture_output=True, text=True, timeout=10,
        )

    def call(self, expression):
        return subprocess.run(
            ["/usr/bin/osascript", "-e", f'set navigation to load script POSIX file "{self.compiled}"',
             "-e", expression],
            capture_output=True, text=True, timeout=10,
        )

    def test_next_and_previous_wrap_at_each_end(self):
        for current, count, direction, expected in [
            (1, 3, "next", 2), (2, 3, "prev", 1),
            (3, 3, "next", 1), (1, 3, "prev", 3),
            (1, 1, "next", 1), (1, 1, "prev", 1),
            (0, 0, "next", 0),
        ]:
            with self.subTest(current=current, count=count, direction=direction):
                result = self.call(f'targetIndex({current}, {count}, "{direction}") of navigation')

                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.strip(), str(expected))

    def test_unknown_direction_is_rejected_before_controlling_brave(self):
        result = self.call('run script navigation with parameters {"invalid"}')

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Expected next or prev", result.stderr)

    def test_missing_direction_is_rejected_before_controlling_brave(self):
        result = self.call('run script navigation with parameters {}')

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Expected one direction", result.stderr)


if __name__ == "__main__":
    unittest.main()
