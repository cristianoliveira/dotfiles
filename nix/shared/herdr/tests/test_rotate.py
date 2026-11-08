"""Rotate pane identities without moving the layout's geometry or losing other edits."""
import copy
import importlib.util
import io
import json
import subprocess
import sys
from pathlib import Path
from contextlib import redirect_stdout, redirect_stderr
import unittest
from unittest.mock import patch


PATH = Path(__file__).resolve().parents[1] / "mods/tmux-compat/rotate.py"
SPEC = importlib.util.spec_from_file_location("rotate", PATH)
rotate = importlib.util.module_from_spec(SPEC)
with patch.object(sys, "dont_write_bytecode", True):
    SPEC.loader.exec_module(rotate)


def pane(name, size=None):
    node = {"id": name, "type": "block", "content": {"terminal": "t" + name}}
    if size is not None:
        node["size"] = {"weight": size}
    return node


def document(root):
    return {"spaces": [{"id": "space", "tabs": [{"id": "tab", "root": root},
            {"id": "other", "root": pane("untouched")}]}], "future": {"preserve": True}}


def context(ids, focus="a", machine=None):
    return {"space": "space", "tab": "tab", "pane": focus, "panes": ids, "machine": machine}


class RotationTests(unittest.TestCase):
    def test_two_panes_swap_while_focus_stays_in_original_position_and_sizes_stay_put(self):
        original = document({"type": "row", "children": [pane("a", .8), pane("b", .2)]})
        before = copy.deepcopy(original)

        result, target = rotate.rotate_document(original, context(["a", "b"]))

        slots = result["spaces"][0]["tabs"][0]["root"]["children"]
        self.assertEqual([node["id"] for node in slots], ["b", "a"])
        self.assertEqual([node["content"]["terminal"] for node in slots], ["tb", "ta"])
        self.assertEqual([node["size"]["weight"] for node in slots], [.8, .2])
        self.assertEqual(target, "b")
        self.assertEqual(original, before)
        self.assertEqual(result["future"], original["future"])
        self.assertEqual(result["spaces"][0]["tabs"][1], original["spaces"][0]["tabs"][1])

    def test_nested_layout_rotates_all_panes_and_keeps_focus_at_middle_slot(self):
        root = {"type": "row", "children": [pane("a", .7),
                {"type": "column", "size": {"weight": .3}, "children": [pane("b"), pane("c")]}]}
        original = document(root)

        result, target = rotate.rotate_document(original, context(["a", "b", "c"], "b"))

        left, right = result["spaces"][0]["tabs"][0]["root"]["children"]
        self.assertEqual([left["id"], *[node["id"] for node in right["children"]]], ["c", "a", "b"])
        self.assertEqual(target, "a")
        self.assertEqual(right["size"], {"weight": .3})
        self.assertNotIn("size", right["children"][0])

    def test_mod_panes_rotate_with_their_props_and_slot_constraints_do_not_move(self):
        left = {**pane("a"), "min": 300, "max": 900, "resizable": False}
        right = {"type": "block", "id": "b", "content": {"mod": "files", "props": {"folder": "/literal"}}}

        result, target = rotate.rotate_document(document({"type": "column", "children": [left, right]}), context(["a", "b"]))

        slots = result["spaces"][0]["tabs"][0]["root"]["children"]
        self.assertEqual(slots[0]["content"], right["content"])
        self.assertEqual(slots[0]["min"], 300)
        self.assertFalse(slots[0]["resizable"])
        self.assertNotIn("min", slots[1])
        self.assertEqual(target, "b")

    def test_one_pane_is_a_noop(self):
        original = document(pane("a"))

        result, target = rotate.rotate_document(original, context(["a"]))

        self.assertEqual(result, original)
        self.assertEqual(target, "a")

    def test_changed_panes_missing_context_and_unsupported_layout_fail_without_mutation(self):
        valid = document({"type": "row", "children": [pane("a"), pane("b")]})
        cases = [
            (valid, context(["b", "a"])),
            (valid, context(["a", "b"], "missing")),
            (valid, {**context(["a", "b"]), "tab": "missing"}),
            (document({"type": "stack", "children": [pane("a"), pane("b")]}), context(["a", "b"])),
            (document({"type": "row", "children": [pane("a"), pane("a")]}), context(["a", "a"])),
        ]
        for original, scope in cases:
            with self.subTest(scope=scope):
                before = copy.deepcopy(original)
                with self.assertRaises(ValueError):
                    rotate.rotate_document(original, scope)
                self.assertEqual(original, before)

    def test_core_write_uses_exact_read_version_and_preserves_remote_scope(self):
        original = document({"type": "row", "children": [pane("a"), pane("b")]})
        calls = []
        def rpc(method, params):
            calls.append((method, params))
            return {"value": original, "version": 17} if method == "doc.get" else {"version": 18}
        scope = {"space": "maya/space", "tab": "maya/tab", "pane": "maya/a", "panes": ["maya/a", "maya/b"], "machine": "maya"}

        result = rotate.rotate(scope, rpc)

        self.assertEqual(result, {"pane": "maya/b", "changed": True})
        self.assertEqual(calls[0], ("doc.get", {"name": "herdr-app", "on": "maya"}))
        self.assertEqual(calls[1][1]["version"], 17)
        self.assertEqual(calls[1][1]["on"], "maya")
        self.assertEqual(calls[1][0], "doc.set")

    def test_rpc_uses_json_lines_and_a_bounded_connection(self):
        response = {"jsonrpc": "2.0", "id": 1, "result": {"version": 2, "value": {}}}
        process = subprocess.CompletedProcess([], 0, json.dumps(response) + "\n", "")
        with patch.object(rotate.subprocess, "run", return_value=process) as run:
            result = rotate.rpc("doc.get", {"name": "herdr-app", "on": "maya"})

        self.assertEqual(result, response["result"])
        self.assertEqual(run.call_args.args[0], ["hc", "connect"])
        self.assertEqual(run.call_args.kwargs["timeout"], 5)
        messages = [json.loads(line) for line in run.call_args.kwargs["input"].splitlines()]
        self.assertEqual(messages[1]["params"]["on"], "maya")
        self.assertEqual(messages[1]["method"], "doc.get")
        self.assertFalse(messages[0]["params"]["framed"])

    def test_rpc_conflicts_transport_errors_and_invalid_responses_surface_without_retry(self):
        responses = [
            (0, '{"id":1,"error":{"message":"conflict","data":{"kind":"conflict"}}}'),
            (0, '{"id":1,"error":{"message":"unavailable","data":null}}'),
            (0, '[]'), (0, '{"id":1,"error":null}'), (0, ''), (1, ''),
        ]
        for code, stdout in responses:
            with self.subTest(stdout=stdout), patch.object(rotate.subprocess, "run", return_value=subprocess.CompletedProcess([], code, stdout, "")) as run:
                with self.assertRaises(RuntimeError):
                    rotate.rpc("doc.set", {})
                self.assertEqual(run.call_count, 1)
        with patch.object(rotate.subprocess, "run", side_effect=subprocess.TimeoutExpired("hc", 5)):
            with self.assertRaisesRegex(RuntimeError, "timed out"):
                rotate.rpc("doc.set", {})

    def test_mixed_remote_context_is_rejected_before_reading_any_document(self):
        with self.assertRaises(ValueError):
            rotate.rotate(context(["a", "b"], machine="maya"), lambda *_: self.fail("must not call Core"))

    def test_invalid_context_and_versions_never_write(self):
        invalid = [None, {}, {**context(["a", "b"]), "machine": 7},
                   {**context(["a", "b"]), "machine": "bad/name"},
                   {**context(["a", "b"]), "panes": []},
                   {**context(["a", "b"]), "space": "other/space"}]
        for scope in invalid:
            with self.subTest(scope=scope), self.assertRaises(ValueError):
                rotate.rotate(scope, lambda *_: self.fail("must not call Core"))
        for version in [None, True, -1]:
            with self.subTest(version=version):
                calls = []
                def rpc(method, params):
                    calls.append(method)
                    return {"version": version}
                with self.assertRaises(ValueError):
                    rotate.rotate(context(["a", "b"]), rpc)
                self.assertEqual(calls, ["doc.get"])

    def test_cli_prints_structured_result_and_reports_failure_without_a_traceback(self):
        output, error = io.StringIO(), io.StringIO()
        with patch.object(rotate.sys, "argv", ["rotate.py", "{}"]), patch.object(rotate, "rotate", return_value={"pane": "b", "changed": True}):
            with redirect_stdout(output):
                self.assertEqual(rotate.main(), 0)
        self.assertEqual(json.loads(output.getvalue()), {"pane": "b", "changed": True})
        with patch.object(rotate.sys, "argv", ["rotate.py", "{}"]), patch.object(rotate, "rotate", side_effect=RuntimeError("conflict")):
            with redirect_stderr(error):
                self.assertEqual(rotate.main(), 1)
        self.assertEqual(error.getvalue(), "conflict\n")

    def test_version_conflict_is_not_retried(self):
        original = document({"type": "row", "children": [pane("a"), pane("b")]})
        calls = []
        def rpc(method, params):
            calls.append(method)
            if method == "doc.get":
                return {"value": original, "version": 4}
            raise RuntimeError("conflict")

        with self.assertRaisesRegex(RuntimeError, "conflict"):
            rotate.rotate(context(["a", "b"]), rpc)

        self.assertEqual(calls, ["doc.get", "doc.set"])


if __name__ == "__main__":
    unittest.main()
