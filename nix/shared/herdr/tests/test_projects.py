import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "mods/project-picker/projects.py"
SPEC = importlib.util.spec_from_file_location("projects", SCRIPT)
projects = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(projects)


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

    def test_remote_discovery_reuses_only_the_same_machines_space(self):
        folder = self.project("work/repo")
        spaces = [
            {"id": "local", "folder": str(folder), "machine": None},
            {"id": "mac/open", "folder": str(folder), "machine": "mac"},
        ]

        result = projects.discover(self.home, spaces, machine="mac")

        self.assertEqual(result["projects"][0]["machine"], "mac")
        self.assertEqual(result["projects"][0]["spaceId"], "mac/open")

    def test_remote_script_runs_without_installing_the_picker_on_that_machine(self):
        self.project("work/agent's $(touch NEVER)")
        calls = []

        def run(argv, **options):
            calls.append(argv)
            return subprocess.run(["python3", "-"], input=options["input"],
                                  env={**os.environ, "HOME": str(self.home)}, text=True, capture_output=True)

        result = projects.remote_projects("mac", [], run=run)

        self.assertEqual(result["projects"][0]["machine"], "mac")
        self.assertEqual(result["projects"][0]["label"], "work/agent's $(touch NEVER)")
        self.assertEqual(calls[0], ["hc", "exec", "--on", "mac", "--timeout", "6", "-i", "--", "python3", "-"])
        self.assertFalse((self.home / "NEVER").exists())

    def test_all_machines_keeps_local_results_when_one_remote_times_out(self):
        self.project("work/local")

        def run(argv, **options):
            if argv[1:3] == ["machine", "ls"]:
                return subprocess.CompletedProcess(argv, 0, json.dumps({"machines": [
                    {"name": "mac", "state": "connected"},
                    {"name": "slow", "state": "connected"},
                    {"name": "offline", "state": "disconnected"},
                    {"name": "temporary", "state": "connected", "temporary": True},
                ]}), "")
            machine = argv[argv.index("--on") + 1]
            self.assertNotIn(machine, ["offline", "temporary"])
            if machine == "slow":
                raise subprocess.TimeoutExpired(argv, options["timeout"])
            return subprocess.CompletedProcess(argv, 0, json.dumps({"projects": [
                {"label": "work/remote", "folder": "/remote/work/remote", "spaceId": None, "machine": machine},
            ], "warnings": []}), "")

        result = projects.discover_all(self.home, [], run=run)

        self.assertEqual([p["label"] for p in result["projects"]], ["work/local", "work/remote"])
        self.assertEqual(len(result["warnings"]), 1)
        self.assertIn("slow", result["warnings"][0])

    def test_machine_listing_has_a_three_second_timeout(self):
        def run(argv, **options):
            self.assertEqual(options["timeout"], 3)
            raise subprocess.TimeoutExpired(argv, options["timeout"])

        with self.assertRaises(subprocess.TimeoutExpired):
            projects.connected_machines(run=run)

    def test_invalid_machine_listing_is_rejected(self):
        for machines in ({}, [None], ["mac"]):
            with self.subTest(machines=machines):
                def run(argv, **options):
                    return subprocess.CompletedProcess(argv, 0, json.dumps({"machines": machines}), "")

                with self.assertRaises(ValueError):
                    projects.connected_machines(run=run)

    def test_machine_listing_failure_keeps_local_projects_and_warns(self):
        self.project("other/local")

        def run(argv, **options):
            return subprocess.CompletedProcess(argv, 1, "", "unavailable")

        result = projects.discover_all(self.home, [], run=run)

        self.assertEqual(result["projects"][0]["label"], "other/local")
        self.assertTrue(result["warnings"])

    def test_remote_failure_and_malformed_output_are_rejected(self):
        for code, output in [
            (1, ""), (0, "not json"), (0, "[]"),
            (0, '{"projects": [{}], "warnings": []}'),
            (0, '{"projects": [], "warnings": [42]}'),
            (0, " " * (2 * 1024 * 1024 + 1)),
        ]:
            with self.subTest(code=code, output=output[:100]):
                def run(argv, **options):
                    return subprocess.CompletedProcess(argv, code, output, "unavailable")

                with self.assertRaises(ValueError):
                    projects.remote_projects("mac", [], run=run)

    def test_malformed_input_exits_without_producing_projects(self):
        result = subprocess.run(
            ["python3", str(SCRIPT), str(self.home), "not json"],
            text=True, capture_output=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")


if __name__ == "__main__":
    unittest.main()
