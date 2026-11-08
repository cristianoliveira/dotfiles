#!/usr/bin/env python3
"""List projects in ~/work and ~/other, optionally on connected Herdr machines."""

import argparse
import json
import subprocess
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path


def discover(home, spaces, machine=""):
    machine_spaces = {
        str(Path(space["folder"]).resolve()): space["id"]
        for space in reversed(spaces)
        if (space.get("machine") or "") == machine and space.get("folder")
    }
    projects = []
    warnings = []

    for workspace in ("work", "other"):
        root = home / workspace
        try:
            entries = list(root.iterdir())
        except FileNotFoundError:
            continue
        except OSError as error:
            warnings.append(f"Cannot read {root}: {error.strerror}")
            continue

        for entry in entries:
            if entry.name.startswith(".") or not entry.is_dir():
                continue
            folder = str(entry.resolve())
            projects.append({
                "label": f"{workspace}/{entry.name}",
                "folder": folder,
                "spaceId": machine_spaces.get(folder),
                **({"machine": machine} if machine else {}),
            })

    projects.sort(key=lambda project: (project["label"].casefold(), project["label"]))
    return {"projects": projects, "warnings": warnings}


def remote_projects(machine, spaces, run=subprocess.run):
    # Send the same scanner over stdin: no remote installation or shell expansion.
    argv = ["projects.py", "~", json.dumps(spaces), "--machine", machine]
    source = f"import sys\nsys.argv = {argv!r}\n" + Path(__file__).read_text()
    result = run(
        ["hc", "exec", "--on", machine, "--timeout", "6", "-i", "--", "python3", "-"],
        input=source, text=True, capture_output=True, timeout=8,
    )
    if result.returncode != 0:
        raise ValueError("remote scan failed; check hc machine ls and remote python3")
    if len(result.stdout) > 2 * 1024 * 1024:
        raise ValueError("remote project list exceeds 2 MiB")
    data = json.loads(result.stdout)
    if (not isinstance(data, dict)
            or not isinstance(data.get("projects"), list)
            or not isinstance(data.get("warnings"), list)):
        raise ValueError("invalid remote project list")
    if not all(isinstance(warning, str) for warning in data["warnings"]):
        raise ValueError("invalid remote warnings")
    for project in data["projects"]:
        if (not isinstance(project, dict)
                or not all(isinstance(project.get(key), str) and project[key] for key in ("label", "folder"))
                or not isinstance(project.get("spaceId"), (str, type(None)))):
            raise ValueError("invalid remote project")
        project["machine"] = machine
    return data


def connected_machines(run=subprocess.run):
    listing = run(["hc", "machine", "ls", "--json"],
                  text=True, capture_output=True, timeout=3)
    if listing.returncode != 0:
        raise ValueError("machine listing failed; check hc machine ls")
    machines = json.loads(listing.stdout)["machines"]
    if not isinstance(machines, list) or not all(isinstance(m, dict) for m in machines):
        raise ValueError("invalid machine list; check hc machine ls")
    return [m["name"] for m in machines
            if m.get("state") == "connected" and not m.get("temporary")
            and isinstance(m.get("name"), str) and m["name"]]


def discover_all(home, spaces, run=subprocess.run):
    result = discover(home, spaces)
    try:
        names = connected_machines(run=run)
    except (OSError, subprocess.TimeoutExpired, ValueError, KeyError, TypeError, AttributeError):
        result["warnings"].append("Cannot list remote machines; check hc machine ls.")
        return result

    def scan(machine):
        try:
            remote = remote_projects(machine, spaces, run=run)
            remote["warnings"] = [f"{machine}: {warning}" for warning in remote["warnings"]]
            return remote
        except (OSError, subprocess.TimeoutExpired, ValueError) as error:
            return {"projects": [], "warnings": [f"Cannot load projects on {machine}: {error}"]}

    # Preserve discovery order even when remote responses finish in another order.
    with ThreadPoolExecutor(max_workers=4) as pool:
        for remote in pool.map(scan, names):
            result["projects"].extend(remote["projects"])
            result["warnings"].extend(remote["warnings"])
    return result


def main():
    parser = argparse.ArgumentParser(
        description=__doc__,
        epilog="Example: python3 projects.py ~ '[]' --all-machines. "
               "Requires hc locally and python3 on each connected machine.",
    )
    parser.add_argument("home", type=Path)
    parser.add_argument("spaces", help="JSON array of current Herdr spaces")
    parser.add_argument("--machine", default="", help="Machine owning the scanned folders")
    targets = parser.add_mutually_exclusive_group()
    targets.add_argument("--all-machines", action="store_true", help="Also scan connected Herdr machines (requires remote python3)")
    targets.add_argument("--remote", help="Scan one connected machine via hc exec (requires remote python3)")
    targets.add_argument("--list-machines", action="store_true", help="List connected, non-temporary machines (three-second timeout)")
    args = parser.parse_args()
    try:
        spaces = json.loads(args.spaces)
        if not isinstance(spaces, list):
            raise ValueError("spaces must be a JSON array")
        if args.list_machines:
            result = {"machines": connected_machines()}
        elif args.remote:
            result = remote_projects(args.remote, spaces)
        elif args.all_machines:
            result = discover_all(args.home.expanduser(), spaces)
        else:
            result = discover(args.home.expanduser(), spaces, machine=args.machine)
    except (ValueError, KeyError, TypeError, OSError, subprocess.TimeoutExpired) as error:
        parser.exit(1, f"Project discovery failed: {error}\n")
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
