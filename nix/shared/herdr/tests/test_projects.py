import json
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "mods/project-picker/projects.py"


class ProjectDiscoveryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)

    def discover(self, spaces=None):
        result = subprocess.run(
            ["python3", str(SCRIPT), str(self.home), json.dumps(spaces or [])],
            text=True, capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def project(self, name):
        folder = self.home / name
        folder.mkdir(parents=True)
        return folder

    def test_lists_only_immediate_workspace_directories_in_stable_order(self):
        self.project("work/zebra/nested")
        self.project("other/alpha")
        self.project("outside/hidden")
        (self.home / "work/file.txt").write_text("not a project")

        result = self.discover()

        self.assertEqual([p["label"] for p in result["projects"]], ["other/alpha", "work/zebra"])
        self.assertEqual(result["warnings"], [])

    def test_ignores_dot_directories_and_hidden_symlinks_in_both_workspaces(self):
        visible = self.project("outside/repo")
        for workspace in ("work", "other"):
            self.project(f"{workspace}/visible")
            self.project(f"{workspace}/.hidden")
            (self.home / workspace / ".linked").symlink_to(visible, target_is_directory=True)

        result = self.discover()

        self.assertEqual([p["label"] for p in result["projects"]],
                         ["other/visible", "work/visible"])
        self.assertEqual(result["warnings"], [])

    def test_missing_roots_return_empty_list(self):
        self.assertEqual(self.discover(), {"projects": [], "warnings": []})

    def test_follows_directory_symlinks_but_ignores_broken_links(self):
        target = self.project("outside/repo")
        self.project("work")
        (self.home / "work/linked").symlink_to(target, target_is_directory=True)
        (self.home / "work/broken").symlink_to(self.home / "absent")

        result = self.discover()

        self.assertEqual(result["projects"], [{
            "label": "work/linked", "folder": str(target.resolve()), "spaceId": None,
        }])

    def test_reuses_local_space_by_canonical_folder_not_remote_space(self):
        folder = self.project("work/repo")
        alias = self.home / "alias"
        alias.symlink_to(folder, target_is_directory=True)
        spaces = [
            {"id": "remote", "folder": str(folder), "machine": "server"},
            {"id": "local", "folder": str(alias), "machine": None},
        ]

        result = self.discover(spaces)

        self.assertEqual(result["projects"][0]["spaceId"], "local")

    def test_special_names_remain_literal_paths(self):
        folder = self.project("work/agent's $(touch NEVER); 日本語")

        result = self.discover()

        self.assertEqual(result["projects"][0]["folder"], str(folder.resolve()))
        self.assertEqual(result["projects"][0]["label"], "work/agent's $(touch NEVER); 日本語")
        self.assertFalse((self.home / "NEVER").exists())

    def test_reports_invalid_workspace_without_hiding_other_projects(self):
        (self.home / "work").write_text("not a directory")
        self.project("other/repo")

        result = self.discover()

        self.assertEqual([p["label"] for p in result["projects"]], ["other/repo"])
        self.assertEqual(len(result["warnings"]), 1)
        self.assertIn("work", result["warnings"][0])

    def test_malformed_input_exits_without_producing_projects(self):
        result = subprocess.run(
            ["python3", str(SCRIPT), str(self.home), "not json"],
            text=True, capture_output=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")


if __name__ == "__main__":
    unittest.main()
