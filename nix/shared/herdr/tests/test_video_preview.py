import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "mods/video-preview/video.py"
SPEC = importlib.util.spec_from_file_location("video_preview", SCRIPT)
video = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(video)


class RunningPlayer:
    def __init__(self):
        self.pid = 123

    def wait(self, timeout):
        raise subprocess.TimeoutExpired("mpv", timeout)


class VideoPreviewTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.path = self.root / "video's $(touch NEVER).mp4"
        self.path.write_bytes(b"fixture")

    def probe(self, argv, **options):
        self.assertEqual(options["timeout"], 8)
        self.assertIn("file", argv)
        return subprocess.CompletedProcess(argv, 0, json.dumps({
            "streams": [{"width": 1920, "height": 1080}], "format": {"duration": "12.5"},
        }), "")

    def test_launches_local_video_paused_with_native_controls_and_no_user_scripts(self):
        calls = []
        def spawn(argv, **options):
            calls.append((argv, options))
            return RunningPlayer()
        with patch.object(video.shutil, "which", side_effect=lambda command: f"/bin/{command}"):
            result = video.launch_video(self.path.name, str(self.root), run=self.probe, spawn=spawn)

        argv, options = calls[0]
        self.assertEqual(argv[-2:], ["--", str(self.path)])
        for flag in ["--pause=yes", "--no-config", "--load-scripts=no", "--access-references=no", "--ytdl=no",
                     "--resume-playback=no", "--save-position-on-quit=no"]:
            self.assertIn(flag, argv)
        self.assertTrue(options["start_new_session"])
        self.assertEqual(result["state"], "launched")
        self.assertEqual(result["width"], 1920)
        self.assertEqual(result["duration"], 12.5)
        self.assertFalse((self.root / "NEVER").exists())

    def test_urls_playlists_and_non_regular_files_are_rejected(self):
        for path in ["https://example.test/a.mp4", str(self.root), "a.m3u", "a.mp4" + chr(10) + "b.mp4"]:
            with self.subTest(path=path), self.assertRaises((ValueError, OSError)):
                video.resolve_video(path, str(self.root))

    def test_audio_only_or_oversized_video_is_rejected_before_launch(self):
        for streams in [[], [{"width": 100000, "height": 100000}]]:
            def probe(argv, **options):
                return subprocess.CompletedProcess(argv, 0, json.dumps({"streams": streams, "format": {}}), "")
            with self.subTest(streams=streams), patch.object(video.shutil, "which", return_value="tool"):
                with self.assertRaises(ValueError):
                    video.launch_video(str(self.path), "", run=probe, spawn=lambda *a, **k: self.fail("must not launch"))

    def test_missing_dependencies_and_probe_failure_have_actionable_errors(self):
        with patch.object(video.shutil, "which", return_value=None):
            with self.assertRaisesRegex(ValueError, "mpv"):
                video.launch_video(str(self.path), "")
        def fail(argv, **options):
            return subprocess.CompletedProcess(argv, 1, "", "Invalid video")
        with patch.object(video.shutil, "which", return_value="tool"):
            with self.assertRaisesRegex(ValueError, "Invalid video"):
                video.launch_video(str(self.path), "", run=fail)

    def test_immediate_player_failure_is_reported_not_claimed_as_playing(self):
        class FailedPlayer:
            def wait(self, timeout):
                return 2
        with patch.object(video.shutil, "which", return_value="tool"):
            with self.assertRaisesRegex(ValueError, "mpv exited"):
                video.launch_video(str(self.path), "", run=self.probe, spawn=lambda *a, **k: FailedPlayer())

    def test_closed_player_returns_closed_state_without_claiming_playback(self):
        class ClosedPlayer:
            def wait(self, timeout):
                return 0
        with patch.object(video.shutil, "which", return_value="tool"):
            result = video.launch_video(str(self.path), "", run=self.probe, spawn=lambda *a, **k: ClosedPlayer())
        self.assertEqual(result["state"], "closed")

    def test_invalid_probe_metadata_does_not_start_a_player(self):
        for data in [[], {"streams": "bad"}, {"streams": [None]}]:
            with self.subTest(data=data):
                def run(argv, **options):
                    return subprocess.CompletedProcess(argv, 0, json.dumps(data), "")
                with self.assertRaises(ValueError):
                    video.metadata(self.path, "ffprobe", run=run)

    def test_clipboard_only_accepts_single_local_video_paths(self):
        for text, expected in [(f'"{self.path}"', str(self.path)), ("https://example.test/a.mp4", ""), ("notes", "")]:
            def run(argv, **options):
                self.assertEqual(options["timeout"], 1)
                return subprocess.CompletedProcess(argv, 0, text, "")
            with self.subTest(text=text), patch.object(video.shutil, "which", return_value="clipboard"):
                self.assertEqual(video.clipboard_path(run=run), expected)


if __name__ == "__main__":
    unittest.main()
