import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).resolve().parents[1] / "mods/tmux-compat/copy_mode.py"
spec = importlib.util.spec_from_file_location("copy_mode", SOURCE)
copy_mode = importlib.util.module_from_spec(spec)


class CopyModeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec.loader.exec_module(copy_mode)

    def test_snapshot_is_private_literal_data_and_removed_after_viewer_exits(self):
        text = "secret 日本語\nvim: set modeline: !touch NEVER\n"
        paths = []

        def run(argv, **kwargs):
            if argv[0] == "hc":
                self.assertEqual(argv, ["hc", "read", "--json", "--lines", "10000", "mac/t3"])
                return subprocess.CompletedProcess(argv, 0, json.dumps({"text": text}), "")
            self.assertEqual(argv[0], "nvim")
            self.assertEqual(kwargs["env"]["HERDR_COPY_SCREEN_ONLY"], "0")
            self.assertIn("-M", argv)
            self.assertIn("--noplugin", argv)
            snapshot = Path(argv[-1])
            paths.append(snapshot)
            self.assertEqual(snapshot.read_text(), text)
            self.assertEqual(snapshot.stat().st_mode & 0o777, 0o600)
            self.assertEqual(snapshot.parent.stat().st_mode & 0o777, 0o700)
            return subprocess.CompletedProcess(argv, 0)

        with patch.object(copy_mode.subprocess, "run", side_effect=run):
            self.assertEqual(copy_mode.view("mac/t3"), 0)
        self.assertFalse(paths[0].exists())

    def test_failed_or_invalid_capture_never_starts_editor(self):
        for code, output in [(1, ""), (0, "not json"), (0, '{"text": 42}')]:
            with self.subTest(code=code, output=output):
                with patch.object(copy_mode.subprocess, "run", return_value=subprocess.CompletedProcess([], code, output, "capture failed")) as run:
                    with self.assertRaises(ValueError):
                        copy_mode.view("t3")
                    self.assertEqual(run.call_count, 1)

    def test_slow_scrollback_falls_back_to_screen_only_with_visible_notice(self):
        calls = []

        def run(argv, **kwargs):
            calls.append(argv)
            if argv[0] == "hc":
                self.assertEqual(kwargs["timeout"], 3)
                if argv[argv.index("--lines") + 1] == "10000":
                    raise subprocess.TimeoutExpired(argv, 3)
                self.assertEqual(argv, ["hc", "read", "--json", "--lines", "0", "t3"])
                return subprocess.CompletedProcess(argv, 0, '{"text":"screen text"}', "")
            self.assertEqual(kwargs["env"]["HERDR_COPY_SCREEN_ONLY"], "1")
            self.assertEqual(Path(argv[-1]).read_text(),
                             "[Scrollback capture timed out; showing current screen only.]\n\nscreen text")
            return subprocess.CompletedProcess(argv, 0)

        with patch.object(copy_mode.subprocess, "run", side_effect=run):
            self.assertEqual(copy_mode.view("t3"), 0)
        self.assertEqual(len(calls), 3)

    def test_real_timeout_recovers_using_screen_capture(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            hc = root / "hc"
            hc.write_text(f"#!{sys.executable}\n" + """
import json, sys, time
if sys.argv[sys.argv.index('--lines') + 1] == '10000':
    time.sleep(30)
else:
    print(json.dumps({'text': 'FALLBACK_TEST'}))
""")
            editor = root / "nvim"
            editor.write_text(f"#!{sys.executable}\n" + """
from pathlib import Path
import os, sys
assert os.environ['HERDR_COPY_SCREEN_ONLY'] == '1'
text = Path(sys.argv[-1]).read_text()
assert text.startswith('[Scrollback capture timed out; showing current screen only.]')
assert text.endswith('FALLBACK_TEST')
print('fallback viewer opened')
""")
            hc.chmod(0o700)
            editor.chmod(0o700)

            result = subprocess.run(
                [sys.executable, str(SOURCE), "--terminal", "t3"],
                env={**os.environ, "PATH": directory + os.pathsep + os.environ["PATH"], "TMPDIR": directory},
                capture_output=True, text=True, timeout=8,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("fallback viewer opened", result.stdout)
            self.assertEqual(list(root.glob("herdr-copy-*")), [])

    def test_unresponsive_screen_also_stops_without_starting_editor(self):
        with patch.object(copy_mode.subprocess, "run", side_effect=subprocess.TimeoutExpired("hc read", 3)) as run:
            with self.assertRaisesRegex(ValueError, "screen capture timed out"):
                copy_mode.view("t3")
            self.assertEqual(run.call_count, 2)

    def test_rejects_options_as_terminal_addresses(self):
        with patch.object(copy_mode.subprocess, "run") as run:
            with self.assertRaises(ValueError):
                copy_mode.view("--help")
            run.assert_not_called()

    def test_oversize_capture_is_rejected(self):
        with patch.object(copy_mode, "MAX_BYTES", 4):
            with patch.object(copy_mode.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, '{"text":"12345"}', "")):
                with self.assertRaises(ValueError):
                    copy_mode.view("t3")

    @unittest.skipUnless(shutil.which("nvim"), "Neovim is required")
    def test_real_viewer_disables_modelines_and_yanks_without_user_config(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            snapshot = root / "snapshot.txt"
            snapshot.write_text("COPY_MODE_TEST\nvim: set ts=99:\n")
            (root / ".nvim.lua").write_text("error('local config must not run')")
            check = """
                assert(not vim.o.modeline and not vim.o.exrc)
                assert(not vim.bo.modifiable and vim.bo.readonly)
                assert(vim.bo.tabstop ~= 99)
                assert(vim.fn.maparg('q', 'n') ~= '')
                assert(vim.o.statusline:find('COPY MODE %(screen only%)'))
                package.loaded['vim.ui.clipboard.osc52'] = {
                    copy = function(reg)
                        assert(reg == '+')
                        return function(lines) _G.copied = lines end
                    end
                }
                vim.cmd('normal! ggyy')
                assert(_G.copied[1] == 'COPY_MODE_TEST')
                _G.copied = nil
                vim.bo.readonly = false
                vim.bo.modifiable = true
                vim.api.nvim_buf_set_lines(0, 0, -1, false, { string.rep('x', 1024 * 1024 + 1) })
                vim.bo.modifiable = false
                vim.bo.readonly = true
                vim.cmd('normal! ggyy')
                assert(_G.copied == nil, 'oversized selection must not reach the clipboard')
            """
            result = subprocess.run([
                "nvim", "--headless", "-u", str(SOURCE.with_name("copy-mode.lua")),
                "--noplugin", "-i", "NONE", "-n", "-R", "-M",
                "-c", "lua " + check, "-c", "qa!", "--", str(snapshot),
            ], cwd=root, env={**os.environ, "HERDR_COPY_SCREEN_ONLY": "1"},
                capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn("Error", result.stderr)

    def test_editor_failure_also_removes_snapshot(self):
        paths = []

        def run(argv, **kwargs):
            if argv[0] == "hc":
                return subprocess.CompletedProcess(argv, 0, '{"text":"data"}', "")
            paths.append(Path(argv[-1]))
            raise OSError("editor unavailable")

        with patch.object(copy_mode.subprocess, "run", side_effect=run):
            with self.assertRaises(OSError):
                copy_mode.view("t3")
        self.assertFalse(paths[0].exists())


if __name__ == "__main__":
    unittest.main()
