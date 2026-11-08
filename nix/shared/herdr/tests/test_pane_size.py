"""Keep pane identities and container metadata when making a small terminal strip."""
import copy
import importlib.util
import io
import json
from contextlib import redirect_stdout
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

PATH = Path(__file__).resolve().parents[1] / "mods/tmux-compat/rotate.py"
SPEC = importlib.util.spec_from_file_location("pane_layout", PATH)
layout = importlib.util.module_from_spec(SPEC)
with patch.object(sys, "dont_write_bytecode", True):
    SPEC.loader.exec_module(layout)


def pane(name):
    return {"type": "block", "id": name, "content": {"terminal": "t-" + name}}


def document(root):
    return {"spaces": [{"id": "space", "tabs": [{"id": "tab", "root": root},
            {"id": "other", "root": pane("untouched")}]}], "future": {"preserve": True}}


def context(ids, focus):
    return {"space": "space", "tab": "tab", "pane": focus, "panes": ids}


class PaneHeightTests(unittest.TestCase):
    def test_either_focused_pane_becomes_a_four_percent_strip_without_changing_identity(self):
        for focus in ("a", "b"):
            with self.subTest(focus=focus):
                original = document({"type": "row", "id": "container", "future": "keep", "children": [pane("a"), pane("b")]})
                before = copy.deepcopy(original)

                result, target = layout.shrink_document(original, context(["a", "b"], focus))

                root = result["spaces"][0]["tabs"][0]["root"]
                self.assertEqual(root["type"], "column")
                self.assertEqual(root["id"], "container")
                self.assertEqual(root["future"], "keep")
                self.assertEqual([node["id"] for node in root["children"]], ["a", "b"])
                self.assertEqual([node["content"] for node in root["children"]], [pane("a")["content"], pane("b")["content"]])
                self.assertAlmostEqual(root["children"]["ab".index(focus)]["size"]["weight"], .04)
                self.assertAlmostEqual(root["children"][1 - "ab".index(focus)]["size"]["weight"], .96)
                self.assertEqual(target, focus)
                self.assertEqual(result["future"], before["future"])
                self.assertEqual(result["spaces"][0]["tabs"][1], before["spaces"][0]["tabs"][1])
                self.assertEqual(original, before)

    def test_nested_splits_keep_container_ids_and_give_freed_height_to_next_pane_like_tmux(self):
        original = document({"type": "row", "id": "outer", "children": [pane("a"),
            {"type": "row", "id": "inner", "size": {"px": 300}, "children": [pane("b"), pane("c")]}]})

        result, target = layout.shrink_document(original, context(list("abc"), "b"))

        root = result["spaces"][0]["tabs"][0]["root"]
        group = root["children"][1]
        self.assertEqual((root["type"], group["type"]), ("column", "column"))
        self.assertEqual((root["id"], group["id"]), ("outer", "inner"))
        self.assertAlmostEqual(root["children"][0]["size"]["weight"], 1/3)
        self.assertAlmostEqual(group["children"][0]["size"]["weight"], .04)
        self.assertAlmostEqual(group["children"][1]["size"]["weight"], 2/3 - .04)
        self.assertAlmostEqual(group["size"]["weight"], 2/3)
        self.assertEqual(target, "b")

    def test_last_pane_gives_freed_height_to_previous_pane(self):
        original = document({"type": "column", "children": [pane("a"), pane("b"), pane("c")]})

        result, _ = layout.shrink_document(original, context(list("abc"), "c"))

        nodes = result["spaces"][0]["tabs"][0]["root"]["children"]
        self.assertAlmostEqual(nodes[0]["size"]["weight"], 1/3)
        self.assertAlmostEqual(nodes[1]["size"]["weight"], 2/3 - .04)
        self.assertAlmostEqual(nodes[2]["size"]["weight"], .04)

    def test_single_pane_and_repeated_shrink_are_noops(self):
        single = document(pane("a"))
        result, _ = layout.shrink_document(single, context(["a"], "a"))
        self.assertEqual(result, single)
        original = document({"type": "column", "children": [pane("a"), pane("b")]})
        shrunk, _ = layout.shrink_document(original, context(["a", "b"], "b"))
        calls = []
        def request(method, params):
            calls.append(method)
            return {"version": 8, "value": shrunk}

        result = layout.rotate(context(["a", "b"], "b"), request, shrink_height=True)

        self.assertEqual(result, {"pane": "b", "changed": False})
        self.assertEqual(calls, ["doc.get"])

    def test_stale_order_constraints_and_excessive_pane_count_fail_without_mutation(self):
        cases = [
            (document({"type": "row", "children": [pane("a"), pane("b")]}), context(["b", "a"], "a")),
            (document({"type": "column", "children": [{**pane("a"), "min": 300}, pane("b")]}), context(["a", "b"], "b")),
            (document({"type": "row", "children": [pane(str(i)) for i in range(26)]}), context([str(i) for i in range(26)], "0")),
        ]
        for original, scope in cases:
            with self.subTest(scope=scope):
                before = copy.deepcopy(original)
                with self.assertRaises(ValueError):
                    layout.shrink_document(original, scope)
                self.assertEqual(original, before)

    def test_remote_shrink_writes_exact_version_and_never_returns_a_rotation_plan(self):
        original = document({"type": "row", "children": [pane("a"), pane("b")]})
        calls = []
        def request(method, params):
            calls.append((method, params))
            return {"version": 17, "value": original} if method == "doc.get" else {"version": 18}
        scope = {"space": "maya/space", "tab": "maya/tab", "pane": "maya/b", "panes": ["maya/a", "maya/b"], "machine": "maya", "native": True}

        result = layout.rotate(scope, request, shrink_height=True)

        self.assertEqual(result, {"pane": "maya/b", "changed": True})
        self.assertEqual(calls[0], ("doc.get", {"name": "herdr-app", "on": "maya"}))
        self.assertEqual((calls[1][0], calls[1][1]["version"], calls[1][1]["on"]), ("doc.set", 17, "maya"))

    def test_cli_selects_height_operation_explicitly(self):
        scope = context(["a", "b"], "b")
        with patch.object(layout.sys, "argv", ["rotate.py", "--shrink-height", json.dumps(scope)]), \
                patch.object(layout, "rotate", return_value={"pane": "b", "changed": True}) as adjust:
            with redirect_stdout(io.StringIO()):
                self.assertEqual(layout.main(), 0)
        adjust.assert_called_once_with(scope, shrink_height=True)

    def test_conflict_does_not_retry(self):
        calls = []
        def request(method, params):
            calls.append(method)
            if method == "doc.get":
                return {"version": 17, "value": document({"type": "column", "children": [pane("a"), pane("b")]})}
            raise RuntimeError("conflict")

        with self.assertRaisesRegex(RuntimeError, "conflict"):
            layout.rotate(context(["a", "b"], "b"), request, shrink_height=True)

        self.assertEqual(calls, ["doc.get", "doc.set"])


if __name__ == "__main__":
    unittest.main()
