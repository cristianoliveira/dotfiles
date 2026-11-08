import os
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import unittest


SCRIPT = Path(__file__).parents[1] / "pi-sessions-backup"


class PiSessionsBackupTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "agent" / "sessions"
        self.source.mkdir(parents=True)
        self.destination = self.root / "backups"
        self.session = self.source / "project with spaces" / "session.jsonl"
        self.session.parent.mkdir()
        self.session.write_text('{"type":"session"}\n')
        (self.source.parent / "auth.json").write_text("not session data")

    def run_backup(self, destination=None, source=None):
        return subprocess.run(
            [sys.executable, str(SCRIPT), str(destination or self.destination),
             "--source", str(source or self.source)],
            capture_output=True, text=True, timeout=10,
        )

    def test_round_trip_preserves_sessions_and_excludes_agent_credentials(self):
        result = self.run_backup()

        self.assertEqual(result.returncode, 0, result.stderr)
        archive = Path(result.stdout.strip())
        self.assertEqual(archive.stat().st_mode & 0o777, 0o600)
        with tarfile.open(archive) as backup:
            self.assertEqual(
                backup.extractfile("sessions/project with spaces/session.jsonl").read(),
                self.session.read_bytes(),
            )
            self.assertFalse(any("auth.json" in name for name in backup.getnames()))
        self.assertEqual(self.session.read_text(), '{"type":"session"}\n')
        self.assertEqual(list(self.destination.glob("*.partial")), [])

    def test_repeated_backups_keep_both_archives(self):
        first = self.run_backup()
        second = self.run_backup()

        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertNotEqual(first.stdout, second.stdout)
        self.assertEqual(len(list(self.destination.glob("*.tar.gz"))), 2)

    def test_missing_source_fails_without_creating_destination(self):
        result = self.run_backup(source=self.root / "missing")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--source", result.stderr)
        self.assertFalse(self.destination.exists())

    def test_destination_inside_source_is_rejected(self):
        result = self.run_backup(destination=self.source / "backups")

        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.source / "backups").exists())

    def test_symlink_destination_inside_source_is_rejected(self):
        link = self.root / "linked-sessions"
        link.symlink_to(self.source, target_is_directory=True)

        result = self.run_backup(destination=link / "backups")

        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.source / "backups").exists())

    def test_symlinks_are_preserved_without_copying_external_contents(self):
        (self.source / "external").symlink_to(self.source.parent / "auth.json")

        result = self.run_backup()

        self.assertEqual(result.returncode, 0, result.stderr)
        with tarfile.open(result.stdout.strip()) as backup:
            self.assertTrue(backup.getmember("sessions/external").issym())

    def test_pi_agent_dir_sets_default_source(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), str(self.destination)],
            env={**os.environ, "PI_AGENT_DIR": str(self.source.parent)},
            capture_output=True, text=True, timeout=10,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        with tarfile.open(result.stdout.strip()) as backup:
            self.assertIn("sessions/project with spaces/session.jsonl", backup.getnames())


if __name__ == "__main__":
    unittest.main()
