import base64
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "mods/image-preview/preview.py"
SPEC = importlib.util.spec_from_file_location("image_preview", SCRIPT)
preview = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(preview)
PNG = base64.b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=")


class ImagePreviewTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.image = self.root / "image's $(touch NEVER).png"
        self.image.write_bytes(PNG)

    def test_reads_relative_paths_without_shell_expansion(self):
        data, details = preview.read_image(self.image.name, str(self.root))

        self.assertEqual(data, PNG)
        self.assertEqual((details["width"], details["height"]), (1, 1))
        self.assertFalse((self.root / "NEVER").exists())

    def test_rejects_non_images_and_oversized_dimensions(self):
        for data in [b"not an image", PNG[:16] + (100000).to_bytes(4, "big") * 2 + PNG[24:]]:
            with self.subTest(data=data[:24]):
                self.image.write_bytes(data)
                with self.assertRaises(ValueError):
                    preview.read_image(str(self.image), "")

    def test_rejects_directories_missing_files_and_large_files(self):
        for path in [self.root, self.root / "missing"]:
            with self.subTest(path=path):
                with self.assertRaises((ValueError, OSError)):
                    preview.read_image(str(path), "")
        with self.image.open("wb") as handle:
            handle.truncate(preview.MAX_BYTES + 1)
        with self.assertRaises(ValueError):
            preview.read_image(str(self.image), "")

    def test_stages_private_asset_in_owned_cache_and_reuses_content_key(self):
        cache = self.root / "cache"
        first = preview.stage_image(PNG, cache)
        second = preview.stage_image(PNG, cache)

        self.assertEqual(first, second)
        self.assertEqual(Path(first["path"]).read_bytes(), PNG)
        self.assertEqual(Path(first["path"]).stat().st_mode & 0o777, 0o600)
        self.assertEqual(cache.stat().st_mode & 0o777, 0o700)

    def test_refuses_unowned_or_symlinked_cache_directory(self):
        for name in ["existing", "linked"]:
            path = self.root / name
            if name == "existing":
                path.mkdir()
            else:
                path.symlink_to(self.root, target_is_directory=True)
            with self.subTest(name=name):
                with self.assertRaises(ValueError):
                    preview.stage_image(PNG, path)

    def test_cache_pruning_leaves_unmanaged_files_and_symlinks_untouched(self):
        cache = self.root / "cache"
        preview.stage_image(PNG, cache)
        unmanaged = cache / "keep.png"
        unmanaged.write_bytes(PNG)
        link = cache / f"image-{'f' * 64}.png"
        link.symlink_to(self.image)
        for index in range(12):
            asset = cache / f"image-{index:064x}.png"
            asset.write_bytes(PNG)
            os.utime(asset, (1, 1))

        preview.stage_image(PNG, cache)

        self.assertTrue(unmanaged.exists())
        self.assertTrue(link.is_symlink())
        self.assertTrue(self.image.exists())
        self.assertLessEqual(len([p for p in cache.iterdir() if preview.ASSET.fullmatch(p.name)
                                  and not p.is_symlink()]), 8)

    def test_jpeg_dimensions_and_broken_headers(self):
        jpeg = bytes.fromhex("ffd8 ffc0 000b 08 0002 0003 01 011100 ffd9")
        self.assertEqual(preview.image_details(jpeg), {"width": 3, "height": 2, "extension": "jpg"})
        for data in [bytes.fromhex("ffd8"), bytes.fromhex("ffd8 ffc0 00ff"), bytes.fromhex("ffd8") + b"bad"]:
            with self.subTest(data=data):
                with self.assertRaises(ValueError):
                    preview.image_details(data)

    def test_clipboard_reads_only_a_single_image_path(self):
        for text, expected in [(f'"{self.image}"', str(self.image)),
                               ("https://example.test/a.png", ""), ("a.png" + chr(10) + "b.png", ""), ("notes", "")]:
            with self.subTest(text=text), patch.object(preview.shutil, "which", return_value="clipboard"):
                def run(argv, **options):
                    self.assertEqual(options["timeout"], 1)
                    return subprocess.CompletedProcess(argv, 0, text, "")
                self.assertEqual(preview.clipboard_path(run=run), expected)

    def test_remote_read_transmits_literal_path_without_installing_mod(self):
        calls = []

        def run(argv, **options):
            calls.append(argv)
            return subprocess.run(["python3", "-"], input=options["input"],
                                  env={**os.environ, "HOME": str(self.root)}, text=True, capture_output=True)

        data = preview.remote_image("mac", self.image.name, str(self.root), run=run)

        self.assertEqual(data, PNG)
        self.assertEqual(calls[0], ["hc", "exec", "--on", "mac", "--timeout", "6", "-i", "--", "python3", "-"])
        self.assertFalse((self.root / "NEVER").exists())

    def test_remote_failure_or_malformed_data_is_rejected(self):
        for code, output in [(1, ""), (0, "{}"), (0, '{"data":"not base64"}')]:
            with self.subTest(code=code, output=output):
                def run(argv, **options):
                    return subprocess.CompletedProcess(argv, code, output, "failed")
                with self.assertRaises(ValueError):
                    preview.remote_image("mac", "image.png", "", run=run)

    def test_cli_stages_image_and_returns_metadata(self):
        result = subprocess.run(["python3", str(SCRIPT), str(self.image), "--cache", str(self.root / "cache")],
                                text=True, capture_output=True, timeout=5)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["width"], 1)


if __name__ == "__main__":
    unittest.main()
