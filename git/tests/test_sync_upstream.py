import os
import pathlib
import shlex
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).parents[1] / "sync-upstream.sh"


class UpstreamSyncTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles-sync-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = pathlib.Path(self.temp.name)
        self.env = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
        self.env.update(GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull,
                        GIT_TERMINAL_PROMPT="0", MAIN_BRANCH="main")
        self.origin = self.root / "origin.git"
        self.work = self.root / "work"
        self.git(self.root, "init", "--bare", "--initial-branch=main", str(self.origin))
        self.git(self.root, "clone", str(self.origin), str(self.work))
        self.commit(self.work, "base")
        self.git(self.work, "push", "origin", "main")

    def git(self, cwd, *args, check=True):
        result = subprocess.run(["git", "-c", "user.name=Sync Test", "-c", "user.email=sync@example.invalid",
                                 "-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null", *args],
                                cwd=cwd, env=self.env, capture_output=True, text=True, timeout=5)
        if check and result.returncode:
            self.fail(result.stderr)
        return result

    def commit(self, repo, text):
        (repo / "file").write_text(text)
        self.git(repo, "add", "file")
        self.git(repo, "commit", "-m", text)
        return self.git(repo, "rev-parse", "HEAD").stdout.strip()

    def remote_commit(self, text):
        peer = self.root / "peer"
        self.git(self.root, "clone", str(self.origin), str(peer))
        head = self.commit(peer, text)
        self.git(peer, "push", "origin", "main")
        return head

    def sync(self):
        return subprocess.run(["bash", str(SCRIPT)], cwd=self.work, env=self.env,
                              capture_output=True, text=True, timeout=10)

    def assert_no_rebase(self):
        self.assertFalse((self.work / ".git/rebase-merge").exists())
        self.assertFalse((self.work / ".git/rebase-apply").exists())

    def test_local_commits_are_preserved_when_upstream_is_already_contained(self):
        before = self.commit(self.work, "local")

        result = self.sync()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git(self.work, "rev-parse", "HEAD").stdout.strip(), before)
        self.assert_no_rebase()

    def test_merge_containing_upstream_is_not_flattened_or_replayed(self):
        self.commit(self.work, "local")
        self.remote_commit("conflicting remote")
        self.git(self.work, "fetch", "origin")
        self.git(self.work, "merge", "-s", "ours", "--no-edit", "origin/main")
        before = self.git(self.work, "rev-parse", "HEAD").stdout

        result = self.sync()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git(self.work, "rev-parse", "HEAD").stdout, before)
        self.assertEqual((self.work / "file").read_text(), "local")
        self.assert_no_rebase()

    def test_untracked_work_and_detached_head_are_not_changed(self):
        untracked = self.work / "unfinished"
        untracked.write_text("keep me")
        self.assertEqual(self.sync().returncode, 0)
        self.assertEqual(untracked.read_text(), "keep me")
        untracked.unlink()
        self.git(self.work, "checkout", "--detach")
        before = self.git(self.work, "rev-parse", "HEAD").stdout
        result = self.sync()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("detached", result.stdout)
        self.assertEqual(self.git(self.work, "rev-parse", "HEAD").stdout, before)

    def test_remote_only_commits_fast_forward_without_rewriting_history(self):
        remote = self.remote_commit("remote")

        result = self.sync()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git(self.work, "rev-parse", "HEAD").stdout.strip(), remote)
        self.assertEqual((self.work / "file").read_text(), "remote")
        self.assert_no_rebase()

    def test_conflicting_divergence_leaves_local_commit_and_worktree_unchanged(self):
        before = self.commit(self.work, "local")
        self.remote_commit("conflicting remote")

        result = self.sync()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("diverged", result.stdout)
        self.assertEqual(self.git(self.work, "rev-parse", "HEAD").stdout.strip(), before)
        self.assertEqual((self.work / "file").read_text(), "local")
        self.assertEqual(self.git(self.work, "status", "--porcelain").stdout, "")
        self.assert_no_rebase()

    def test_staged_and_unstaged_edits_are_not_touched(self):
        before = self.git(self.work, "rev-parse", "HEAD").stdout
        for staged in [False, True]:
            with self.subTest(staged=staged):
                (self.work / "file").write_text("unfinished")
                if staged:
                    self.git(self.work, "add", "file")
                status = self.git(self.work, "status", "--porcelain").stdout

                result = self.sync()

                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self.git(self.work, "status", "--porcelain").stdout, status)
                self.assertEqual(self.git(self.work, "rev-parse", "HEAD").stdout, before)

    def test_existing_manual_rebase_is_not_continued_or_aborted(self):
        self.commit(self.work, "local")
        self.remote_commit("conflicting remote")
        self.git(self.work, "fetch", "origin")
        self.assertNotEqual(self.git(self.work, "rebase", "origin/main", check=False).returncode, 0)
        before = self.git(self.work, "status", "--porcelain").stdout

        result = self.sync()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git(self.work, "status", "--porcelain").stdout, before)
        self.assertTrue((self.work / ".git/rebase-merge").is_dir())

    def test_work_appearing_during_fetch_prevents_fast_forward(self):
        self.remote_commit("remote")
        before = self.git(self.work, "rev-parse", "HEAD").stdout
        shim = self.root / "shim"
        shim.mkdir()
        real_git = shlex.quote(shutil.which("git"))
        wrapper = shim / "git"
        wrapper.write_text(f'#!/bin/sh\nif [ "$1" = fetch ]; then\n  {real_git} "$@" || exit $?\n  printf unfinished > appeared\nelse\n  exec {real_git} "$@"\nfi\n')
        wrapper.chmod(0o755)
        self.env["PATH"] = str(shim) + os.pathsep + self.env["PATH"]

        result = self.sync()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git(self.work, "rev-parse", "HEAD").stdout, before)
        self.assertEqual((self.work / "file").read_text(), "base")
        self.assertEqual((self.work / "appeared").read_text(), "unfinished")

    def test_fetch_failure_surfaces_without_mutating_local_history(self):
        before = self.git(self.work, "rev-parse", "HEAD").stdout
        self.git(self.work, "remote", "set-url", "origin", str(self.root / "missing.git"))

        result = self.sync()

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.git(self.work, "rev-parse", "HEAD").stdout, before)
        self.assert_no_rebase()

    def test_missing_upstream_reports_configuration_error(self):
        self.env["MAIN_BRANCH"] = "not-present"

        result = self.sync()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("MAIN_BRANCH", result.stderr)
        self.assert_no_rebase()
