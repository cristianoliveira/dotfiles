#!/usr/bin/env python3
"""Preview a local video in an independent, paused mpv window (no CLI installation)."""

import argparse
import json
import math
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile

EXTENSIONS = {".mp4", ".m4v", ".mov", ".mkv", ".webm", ".avi", ".ogv", ".mpg", ".mpeg", ".ts", ".m2ts", ".flv", ".wmv"}
FORMATS = "mov,matroska,avi,ogg,mpegts,mpeg,flv,asf"


def resolve_video(value, cwd):
    path = value.strip()
    if len(path) >= 2 and path[0] == path[-1] and path[0] in ('"', "'"):
        path = path[1:-1]
    if not path or "://" in path or any(character in path for character in (chr(0), chr(10), chr(13))):
        raise ValueError("Paste one local video path, not a URL or playlist.")
    source = Path(path).expanduser()
    if source.suffix.lower() not in EXTENSIONS:
        raise ValueError("Choose a video such as MP4, MOV, MKV or WebM; playlists are not supported.")
    if not source.is_absolute():
        source = Path(cwd or Path.home()) / source
    source = source.resolve(strict=True)
    info = source.stat()
    if not stat.S_ISREG(info.st_mode):
        raise ValueError("Choose a regular local video file.")
    if info.st_size > 4 * 1024 ** 3:
        raise ValueError("Video exceeds the 4 GiB preview limit.")
    return source


def metadata(path, ffprobe, run=subprocess.run):
    result = run([ffprobe, "-v", "error", "-protocol_whitelist", "file", "-format_whitelist", FORMATS,
                  "-select_streams", "v:0", "-show_entries", "stream=width,height:format=duration", "-of", "json", str(path)],
                 text=True, capture_output=True, timeout=8)
    if result.returncode:
        raise ValueError(f"Cannot read this video: {result.stderr.strip()[:2000]}")
    data = json.loads(result.stdout)
    if not isinstance(data, dict) or not isinstance(data.get("streams"), list):
        raise ValueError("ffprobe returned invalid video metadata.")
    stream = next(iter(data["streams"]), {})
    if not isinstance(stream, dict):
        raise ValueError("ffprobe returned an invalid video stream.")
    width, height = stream.get("width", 0), stream.get("height", 0)
    if not isinstance(width, int) or not isinstance(height, int) or width < 1 or height < 1 or width * height > 25_000_000:
        raise ValueError("No video stream, invalid dimensions, or video exceeds 25 megapixels.")
    try:
        duration = float(data.get("format", {}).get("duration", "nan"))
    except (ValueError, TypeError, AttributeError):
        duration = math.nan
    return {"width": width, "height": height, "duration": duration if math.isfinite(duration) and duration >= 0 else None}


def launch_video(value, cwd, run=subprocess.run, spawn=subprocess.Popen):
    source = resolve_video(value, cwd)
    player = shutil.which("mpv")
    probe = shutil.which("ffprobe")
    if not player or not probe:
        raise ValueError("mpv and ffprobe must be on Herdr's PATH. Check `command -v mpv ffprobe` in the shell used to launch Herdr.")
    details = metadata(source, probe, run=run)
    command = [player, "--no-config", "--load-scripts=no", "--ytdl=no", "--access-references=no",
               "--autocreate-playlist=no", "--sub-auto=no", "--audio-file-auto=no",
               "--resume-playback=no", "--save-position-on-quit=no",
               "--demuxer-lavf-o=protocol_whitelist=file", "--no-terminal", "--msg-level=all=error",
               "--pause=yes", "--keep-open=yes", "--force-window=immediate", "--autofit=90%x90%",
               "--title=Herdr Video Preview", "--osc=yes",
               f"--input-conf={Path(__file__).with_name('input.conf')}", "--", str(source)]
    # No inherited pipes: the player is an independent visible window, not a
    # helper whose lifetime should block Herdr's exec request.
    with tempfile.TemporaryFile(mode="w+") as errors:
        process = spawn(command, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=errors, start_new_session=True)
        try:
            code = process.wait(timeout=0.35)
        except subprocess.TimeoutExpired:
            return {"state": "launched", "path": str(source), "paused": True, "playback_status": "unchecked", **details}
        if code:
            errors.seek(0)
            raise ValueError(f"mpv exited before preview opened: {errors.read(2000).strip() or f'exit {code}'}")
    return {"state": "closed", "path": str(source), **details}


def clipboard_path(run=subprocess.run):
    commands = [["pbpaste"]] if sys.platform == "darwin" else [
        ["wl-paste", "--no-newline"], ["xclip", "-selection", "clipboard", "-o"],
    ]
    for command in commands:
        if not shutil.which(command[0]):
            continue
        try:
            result = run(command, text=True, capture_output=True, timeout=1)
            path = result.stdout.strip()
            if len(path) >= 2 and path[0] == path[-1] and path[0] in ('"', "'"):
                path = path[1:-1]
            if (result.returncode == 0 and path and len(path) <= 4096 and "://" not in path
                    and not any(c in path for c in (chr(0), chr(10), chr(13)))
                    and Path(path).suffix.lower() in EXTENSIONS):
                return path
        except (OSError, UnicodeError, subprocess.TimeoutExpired):
            continue
    return ""


def main():
    parser = argparse.ArgumentParser(description=__doc__, epilog=(
        "Example: python3 video.py ~/Videos/demo.mp4. Requires existing mpv and ffprobe on this computer. "
        "Space plays/pauses, arrows seek, F toggles fullscreen, Esc closes the player. Local paths only."))
    parser.add_argument("path", nargs="?", default="")
    parser.add_argument("--cwd", default="", help="Base directory for relative paths (defaults to local home)")
    parser.add_argument("--clipboard", action="store_true", help="Read a local video file path from clipboard text")
    args = parser.parse_args()
    try:
        result = {"path": clipboard_path()} if args.clipboard else launch_video(args.path, args.cwd)
        print(json.dumps({"ok": True, **result}))
        return 0
    except (ValueError, OSError, TypeError, subprocess.TimeoutExpired) as error:
        print(json.dumps({"ok": False, "error": str(error)}))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
