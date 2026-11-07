#!/usr/bin/env python3
"""Open a terminal snapshot in an isolated, read-only keyboard copy viewer."""

import argparse
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import tempfile


MAX_BYTES = 8 * 1024 * 1024


def capture(terminal, lines):
    return subprocess.run(
        ["hc", "read", "--json", "--lines", str(lines), terminal],
        capture_output=True, text=True, timeout=3,
    )


def view(terminal):
    if not re.fullmatch(r"(?:[A-Za-z0-9_.-]+/)?t[a-z0-9]+", terminal):
        raise ValueError("Focus a terminal with a valid Herdr address first.")
    notice = ""
    try:
        result = capture(terminal, 10000)
    except subprocess.TimeoutExpired:
        try:
            result = capture(terminal, 0)
        except subprocess.TimeoutExpired as error:
            raise ValueError("Terminal screen capture timed out; hc read did not respond.") from error
        notice = "[Scrollback capture timed out; showing current screen only.]\n\n"
    if result.returncode:
        raise ValueError("Cannot capture terminal text. Check the terminal and machine connection.")
    try:
        text = json.loads(result.stdout)["text"]
    except (ValueError, KeyError, TypeError) as error:
        raise ValueError("Herdr returned an invalid terminal snapshot.") from error
    if not isinstance(text, str) or len(text.encode("utf-8")) > MAX_BYTES:
        raise ValueError("Terminal snapshot is invalid or exceeds 8 MiB.")

    with tempfile.TemporaryDirectory(prefix="herdr-copy-") as directory:
        snapshot = Path(directory) / "scrollback.txt"
        with os.fdopen(os.open(snapshot, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), "w", encoding="utf-8") as file:
            file.write(notice + text)
        config = Path(__file__).with_name("copy-mode.lua")
        return subprocess.run([
            "nvim", "-u", str(config), "--noplugin", "-i", "NONE", "-n", "-R", "-M",
            "--", str(snapshot),
        ], env={**os.environ, "HERDR_COPY_SCREEN_ONLY": "1" if notice else "0"}).returncode


def stop(_signal, _frame):
    raise SystemExit(0)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--terminal", required=True)
    args = parser.parse_args()
    for name in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(name, stop)
    try:
        return view(args.terminal)
    except (ValueError, OSError, subprocess.TimeoutExpired) as error:
        print(f"Copy mode failed: {error}", flush=True)
        input("Press Enter to close.")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
