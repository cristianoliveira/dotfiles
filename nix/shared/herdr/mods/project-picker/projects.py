#!/usr/bin/env python3
"""List immediate projects in ~/work and ~/other for the Herdr popup."""

import argparse
import json
from pathlib import Path


def discover(home, spaces):
    local_spaces = {
        str(Path(space["folder"]).resolve()): space["id"]
        for space in reversed(spaces)
        if not space.get("machine") and space.get("folder")
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
                "spaceId": local_spaces.get(folder),
            })

    projects.sort(key=lambda project: (project["label"].casefold(), project["label"]))
    return {"projects": projects, "warnings": warnings}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("home", type=Path)
    parser.add_argument("spaces", help="JSON array of current Herdr spaces")
    args = parser.parse_args()
    try:
        spaces = json.loads(args.spaces)
        if not isinstance(spaces, list):
            raise ValueError("spaces must be a JSON array")
        result = discover(args.home, spaces)
    except (ValueError, KeyError, TypeError, OSError) as error:
        parser.exit(1, f"Project discovery failed: {error}\n")
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
