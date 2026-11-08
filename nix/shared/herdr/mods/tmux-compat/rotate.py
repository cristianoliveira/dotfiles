#!/usr/bin/env python3
"""Adjust Herdr pane layouts with scoped, versioned edits and optional native rotation plans."""
import argparse
import copy
import json
import subprocess
import sys


GEOMETRY = ("size", "min", "max", "resizable")


def normalize_context(context):
    if not isinstance(context, dict):
        raise ValueError("Pane layout adjustment needs a tab pane context.")
    machine = context.get("machine")
    if machine is not None and (not isinstance(machine, str) or not machine or "/" in machine):
        raise ValueError("Invalid pane layout machine.")
    prefix = machine + "/" if machine else ""

    def local_id(value):
        if not isinstance(value, str) or not value or len(value) > 512:
            raise ValueError("Invalid pane layout context.")
        if prefix and not value.startswith(prefix):
            raise ValueError("Pane layout context belongs to another machine.")
        value = value[len(prefix):]
        if not value or "/" in value:
            raise ValueError("Invalid machine-qualified pane id.")
        return value

    panes = context.get("panes")
    if not isinstance(panes, list) or not 1 <= len(panes) <= 1000:
        raise ValueError("Pane layout adjustment needs 1–1000 panes in one tab.")
    return {"space": local_id(context.get("space")), "tab": local_id(context.get("tab")),
            "pane": local_id(context.get("pane")), "panes": [local_id(pane) for pane in panes], "machine": machine}


def validated_layout(value, context):
    if not isinstance(value, dict) or not isinstance(value.get("spaces"), list):
        raise ValueError("Unsupported Herdr layout document.")
    result = copy.deepcopy(value)
    space = next((space for space in result["spaces"] if isinstance(space, dict) and space.get("id") == context["space"]), None)
    tabs = (space or {}).get("tabs", [])
    if not isinstance(tabs, list):
        raise ValueError("Unsupported Herdr tab list.")
    tab = next((tab for tab in tabs if isinstance(tab, dict) and tab.get("id") == context["tab"]), None)
    if tab is None:
        raise ValueError("The original tab is no longer available.")
    leaves = []

    def visit(node):
        if not isinstance(node, dict):
            raise ValueError("Unsupported pane layout.")
        if node.get("type") in ("row", "column") and isinstance(node.get("children"), list) and node["children"]:
            for child in node["children"]:
                visit(child)
            return
        content = node.get("content")
        if (node.get("type") != "block" or not isinstance(node.get("id"), str) or not node["id"]
                or not isinstance(content, dict) or node.get("children")
                or sum(isinstance(content.get(key), str) and bool(content[key]) for key in ("terminal", "mod")) != 1):
            raise ValueError("Unsupported pane layout; wait for panes to finish loading.")
        leaves.append(node)

    visit(tab.get("root"))
    ids = [leaf["id"] for leaf in leaves]
    if ids != context["panes"] or len(set(ids)) != len(ids) or context["pane"] not in ids:
        raise ValueError("Tab panes changed before layout adjustment; try again.")
    return result, tab, leaves


def rotate_document(value, context):
    result, _, leaves = validated_layout(value, context)
    position = context["panes"].index(context["pane"])
    payloads = copy.deepcopy(leaves)
    for index, slot in enumerate(leaves):
        geometry = {key: slot[key] for key in GEOMETRY if key in slot}
        incoming = payloads[(index - 1) % len(payloads)]
        for key in GEOMETRY:
            incoming.pop(key, None)
        incoming.update(geometry)
        slot.clear()
        slot.update(incoming)
    return result, leaves[position]["id"]


def shrink_document(value, context):
    result, tab, leaves = validated_layout(value, context)
    count = len(leaves)
    if count == 1:
        return result, context["pane"]
    if count > 25:
        raise ValueError("Four-percent height needs at most 25 panes; close panes before shrinking.")
    position = context["panes"].index(context["pane"])
    neighbor = position + 1 if position + 1 < count else position - 1
    shares = [1 / count] * count
    shares[neighbor] += shares[position] - .04
    shares[position] = .04
    heights = dict(zip(context["panes"], shares))

    def stack(node, root=False):
        if any(node.get(key) is not None for key in GEOMETRY[1:]):
            raise ValueError("Custom min/max/resizable constraints prevent a four-percent strip; remove those constraints first.")
        if node["type"] == "block":
            height = heights[node["id"]]
        else:
            node["type"] = "column"
            height = sum(stack(child) for child in node["children"])
        # Preserve container identities and metadata: replacing the tree can
        # break Herdr's native split bookkeeping. We only change axis and size.
        if not root:
            node["size"] = {"weight": height}
        return height

    stack(tab["root"], root=True)
    return result, context["pane"]


def native_swaps(root, ids):
    """Plan only splits whose directional neighbors do not depend on pixel sizes."""
    if not 2 <= len(ids) <= 16:
        return None

    def ordinary(node):
        size = node.get("size", {})
        return (isinstance(size, dict) and node.get("type") == "block" and node["content"].get("terminal")
                and not any(key in node for key in GEOMETRY[1:])
                and not node.get("hidden")
                and all(isinstance(value, (int, float)) and value > 0
                        for value in size.values()))

    def flat_children(node):
        children = []
        for child in node.get("children", []):
            if child.get("type") == node.get("type") and not child.get("hidden"):
                children.extend(flat_children(child))
            else:
                children.append(child)
        return children

    axis = root.get("type")
    children = flat_children(root)
    if root.get("hidden") or axis not in ("row", "column"):
        return None
    previous = "left" if axis == "row" else "up"
    if all(ordinary(child) for child in children):
        return [{"pane": pane, "direction": previous} for pane in ids[1:]]
    if len(children) != 2:
        return None
    for master in (0, 1):
        stack = children[1 - master]
        if (not ordinary(children[master]) or stack.get("type") != ("column" if axis == "row" else "row")
                or stack.get("hidden") or not all(ordinary(child) for child in flat_children(stack))):
            continue
        # Native neighbor rectangles are cached for the script turn, keyed by
        # original pane identity. These are identity transpositions, not a walk
        # through freshly rendered positions: visit the small panes in reverse.
        direction = previous if master == 0 else ("right" if axis == "row" else "down")
        others = ids[1:] if master == 0 else ids[:-1]
        return [{"pane": pane, "direction": direction} for pane in reversed(others)]
    return None


def rpc(method, params):
    messages = [{"jsonrpc": "2.0", "id": 0, "method": "hello", "params": {"generation": 1, "framed": False}},
                {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}]
    try:
        process = subprocess.run(["hc", "connect"], input="".join(json.dumps(message) + "\n" for message in messages),
                                 text=True, capture_output=True, timeout=5)
    except subprocess.TimeoutExpired:
        raise RuntimeError(f"Core {method} timed out. Check pane positions before repeating the command.") from None
    if process.returncode:
        raise RuntimeError(f"Could not confirm Core {method}; check pane positions before repeating the command.")
    for line in process.stdout.splitlines():
        response = json.loads(line)
        if not isinstance(response, dict):
            raise RuntimeError(f"Core {method} returned an invalid response.")
        if "error" in response:
            error = response["error"]
            if not isinstance(error, dict):
                raise RuntimeError(f"Core {method} returned an invalid error.")
            data = error.get("data")
            if (isinstance(data, dict) and data.get("kind") == "conflict") or error.get("message") == "conflict":
                raise RuntimeError("Layout changed during the command; no write applied. Try again.")
            raise RuntimeError(f"Core {method}: {error.get('message', 'request failed')}")
        if response.get("id") == 1 and isinstance(response.get("result"), dict):
            return response["result"]
    raise RuntimeError(f"Core {method} returned no result; check pane positions before repeating the command.")


def rotate(context, request=rpc, *, shrink_height=False):
    scope = normalize_context(context)
    if type(context.get("native", False)) is not bool:
        raise ValueError("Native rotation preference must be a boolean.")
    params = {"name": "herdr-app"}
    if scope["machine"]:
        params["on"] = scope["machine"]
    current = request("doc.get", params)
    if type(current.get("version")) is not int or current["version"] < 0:
        raise ValueError("Core returned an invalid layout version.")
    transform = shrink_document if shrink_height else rotate_document
    value, target = transform(current.get("value"), scope)
    changed = value != current.get("value") if shrink_height else len(scope["panes"]) > 1
    prefix = scope["machine"] + "/" if scope["machine"] else ""
    if context.get("native") and changed and not shrink_height:
        tab = next(tab for space in current["value"]["spaces"] if space["id"] == scope["space"]
                   for tab in space["tabs"] if tab["id"] == scope["tab"])
        swaps = native_swaps(tab["root"], scope["panes"])
        if swaps is not None:
            return {"pane": prefix + target, "changed": True,
                    "swaps": [{**step, "pane": prefix + step["pane"]} for step in swaps]}
    if changed:
        request("doc.set", {**params, "value": value, "version": current["version"]})
    return {"pane": prefix + target, "changed": changed}


def main():
    parser = argparse.ArgumentParser(description=__doc__,
        epilog="Needs Python 3 and hc. Normally run: herdr-app do tmux-compat.rotate-panes; "
               "for a four-percent strip: herdr-app do tmux-compat.shrink-height")
    parser.add_argument("--shrink-height", action="store_true",
                        help="Stack panes vertically and shrink the focused pane to 4%% height; keep focus and pane identities.")
    parser.add_argument("context", help="JSON space/tab/pane IDs, ordered panes, optional machine and native boolean; "
                        "native=true prefers a swap plan, otherwise uses a versioned write")
    args = parser.parse_args()
    try:
        print(json.dumps(rotate(json.loads(args.context), shrink_height=args.shrink_height)))
    except (ValueError, RuntimeError, OSError) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
