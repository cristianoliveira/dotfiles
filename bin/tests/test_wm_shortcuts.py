import importlib.util
from importlib.machinery import SourceFileLoader
import json
import subprocess
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).parents[1] / "wm-shortcuts"
spec = importlib.util.spec_from_loader(
    "wm_shortcuts", SourceFileLoader("wm_shortcuts", str(SCRIPT))
)
wm_shortcuts = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = wm_shortcuts
spec.loader.exec_module(wm_shortcuts)


class SwayShortcutsTest(unittest.TestCase):
    def test_reads_default_and_named_mode_bindings(self):
        config = '''
set $mod Mod4
# Open terminal
bindsym $mod+Return exec terminal
mode "resize" {
    # Shrink focused window
    bindsym h resize shrink width 10 px
    bindsym Escape mode "default"
}
bindgesture swipe:4:right workspace next # Next workspace
'''

        shortcuts = wm_shortcuts.parse_sway(config)

        self.assertEqual(
            [(item.mode, item.key, item.action) for item in shortcuts],
            [
                ("default", "$mod+Return", "exec terminal"),
                ("resize", "h", "resize shrink width 10 px"),
                ("resize", "Escape", 'mode "default"'),
                ("default", "swipe:4:right", "workspace next"),
            ],
        )
        self.assertEqual(shortcuts[0].context, "Open terminal")
        self.assertEqual(shortcuts[1].context, "Shrink focused window")
        self.assertEqual(shortcuts[3].context, "Next workspace")

    def test_ignores_comments_and_bindings_without_actions(self):
        shortcuts = wm_shortcuts.parse_sway("# bindsym x ignored\nbindsym x\n")
        self.assertEqual(shortcuts, [])


class AerospaceShortcutsTest(unittest.TestCase):
    def test_reads_comments_from_binding_source(self):
        source = '''
        mode.main.binding = {
          # Open terminal
          cmd-enter = "exec terminal";
          cmd-b = "open browser"; # Open browser
        };
        '''
        comments = wm_shortcuts.parse_aerospace_comments(source)
        self.assertEqual(comments[("main", "cmd-enter")], "Open terminal")
        self.assertEqual(comments[("main", "cmd-b")], "Open browser")

    def test_flattens_all_modes_and_action_lists(self):
        settings = {
            "mode": {
                "main": {"binding": {"cmd-enter": "exec terminal"}},
                "resize": {"binding": {"h": ["resize width -50", "mode main"]}},
            }
        }

        shortcuts = wm_shortcuts.parse_aerospace(settings)

        self.assertEqual(
            [(item.mode, item.key, item.action) for item in shortcuts],
            [
                ("main", "cmd-enter", "exec terminal"),
                ("resize", "h", "resize width -50; mode main"),
            ],
        )

    @patch("subprocess.run")
    def test_eval_failure_has_actionable_error(self, run):
        run.return_value = subprocess.CompletedProcess([], 1, "", "flake failed")
        with self.assertRaisesRegex(RuntimeError, "flake failed"):
            wm_shortcuts.load_aerospace(Path("/dotfiles"))


class OutputTest(unittest.TestCase):
    def test_table_groups_shortcuts_by_mode(self):
        output = wm_shortcuts.format_table([
            wm_shortcuts.Shortcut("main", "cmd-enter", "exec terminal", "Open terminal")
        ])
        self.assertIn("[main]", output)
        self.assertIn("cmd-enter", output)
        self.assertIn("exec terminal", output)
        self.assertIn("# Open terminal", output)


if __name__ == "__main__":
    unittest.main()
