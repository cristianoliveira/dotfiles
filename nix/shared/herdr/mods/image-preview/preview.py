#!/usr/bin/env python3
"""Prepare a bounded PNG/JPEG preview from a local or connected Herdr machine."""

import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import sys
import stat
import struct
import subprocess
import tempfile
import time

MAX_BYTES = 16 * 1024 * 1024
MAX_PIXELS = 25_000_000
OWNER = "herdr-image-preview-v1\n"
ASSET = re.compile(r"image-[0-9a-f]{64}\.(png|jpg)\Z")


def image_details(data):
    if data.startswith(b"\x89PNG\r\n\x1a\n") and len(data) >= 33 and data[12:16] == b"IHDR":
        width, height = struct.unpack(">II", data[16:24])
        extension = "png"
    elif data.startswith(b"\xff\xd8"):
        at = 2
        width = height = 0
        while at < len(data):
            if data[at] != 0xFF:
                break
            while at < len(data) and data[at] == 0xFF:
                at += 1
            if at + 3 > len(data):
                break
            marker = data[at]
            at += 1
            if marker in (0xD9, 0xDA):
                break
            length = int.from_bytes(data[at:at + 2], "big")
            if length < 2 or at + length > len(data):
                break
            if marker in (0xC0, 0xC1, 0xC2):
                if length >= 8:
                    height, width = struct.unpack(">HH", data[at + 3:at + 7])
                break
            at += length
        extension = "jpg"
    else:
        raise ValueError("Use a PNG or JPEG image (not a URL or SVG).")
    if not width or not height or width * height > MAX_PIXELS:
        raise ValueError("Invalid dimensions or image exceeds 25 megapixels.")
    return {"width": width, "height": height, "extension": extension}


def read_image(path, cwd):
    if not path or "\x00" in path or "://" in path:
        raise ValueError("Enter a local file path, not a URL.")
    source = Path(path).expanduser()
    if not source.is_absolute():
        source = Path(cwd or Path.home()) / source
    # O_NONBLOCK avoids hanging on a named pipe; fstat checks the opened file.
    descriptor = os.open(source, os.O_RDONLY | os.O_NONBLOCK)
    with os.fdopen(descriptor, "rb") as handle:
        info = os.fstat(handle.fileno())
        if not stat.S_ISREG(info.st_mode):
            raise ValueError("Choose a regular image file.")
        if info.st_size > MAX_BYTES:
            raise ValueError("Image exceeds 16 MiB.")
        data = handle.read(MAX_BYTES + 1)
    if len(data) > MAX_BYTES:
        raise ValueError("Image exceeds 16 MiB.")
    return data, image_details(data)


def remote_image(machine, path, cwd, run=subprocess.run):
    argv = ["preview.py", path, "--cwd", cwd, "--encode"]
    source = f"import sys\nsys.argv = {argv!r}\n" + Path(__file__).read_text()
    result = run(["hc", "exec", "--on", machine, "--timeout", "6", "-i", "--", "python3", "-"],
                 input=source, text=True, capture_output=True, timeout=8)
    if result.returncode != 0:
        raise ValueError(f"Cannot read image on {machine}; check its path and remote python3.")
    if len(result.stdout) > MAX_BYTES * 2:
        raise ValueError("Remote image exceeds preview limit.")
    try:
        data = base64.b64decode(json.loads(result.stdout)["data"], validate=True)
    except (ValueError, KeyError, TypeError) as error:
        raise ValueError("Invalid remote image response.") from error
    if len(data) > MAX_BYTES:
        raise ValueError("Remote image exceeds 16 MiB.")
    image_details(data)
    return data


def stage_image(data, cache):
    details = image_details(data)
    if cache.is_symlink():
        raise ValueError("Preview cache must not be a symlink.")
    created = not cache.exists()
    cache.mkdir(mode=0o700, parents=True, exist_ok=True)
    marker = cache / ".owner"
    if created:
        marker.write_text(OWNER)
        marker.chmod(0o600)
    if marker.is_symlink() or not marker.is_file() or marker.read_text() != OWNER:
        raise ValueError("Refusing an unowned preview cache directory.")
    if cache.stat().st_mode & 0o077:
        raise ValueError("Preview cache must be private (chmod 700).")
    digest = hashlib.sha256(data).hexdigest()
    destination = cache / f"image-{digest}.{details['extension']}"
    if destination.is_symlink():
        raise ValueError("Refusing a linked preview asset.")
    descriptor, temporary = tempfile.mkstemp(prefix=".image-", dir=cache)
    try:
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(data)
        os.replace(temporary, destination)
    finally:
        Path(temporary).unlink(missing_ok=True)

    # Delete only this mod's regular assets inside its private, marked directory.
    assets = sorted((p for p in cache.iterdir() if ASSET.fullmatch(p.name)
                     and not p.is_symlink() and p.is_file()), key=lambda p: p.stat().st_mtime, reverse=True)
    for index, asset in enumerate(assets):
        if asset != destination and (index >= 8 or time.time() - asset.stat().st_mtime > 86400):
            asset.unlink()
    return {**details, "path": str(destination)}


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
            if (result.returncode == 0 and len(path) <= 4096 and "://" not in path
                    and not any(c in path for c in "\r\n\0")
                    and path.lower().endswith((".png", ".jpg", ".jpeg"))):
                return path
        except (OSError, subprocess.TimeoutExpired, UnicodeError):
            continue
    return ""


def main():
    parser = argparse.ArgumentParser(description=__doc__, epilog=(
        "Example: python3 preview.py ~/Pictures/shot.png --cache ~/.config/herdr-app/image-previews. "
        "For remote files add --machine mac --cwd /Users/me/project. Requires remote python3."))
    parser.add_argument("path", nargs="?", default="")
    parser.add_argument("--clipboard", action="store_true", help="Read an image path from clipboard text (pbpaste/wl-paste/xclip)")
    parser.add_argument("--cwd", default="")
    parser.add_argument("--machine", default="")
    parser.add_argument("--cache", type=Path)
    parser.add_argument("--encode", action="store_true", help=argparse.SUPPRESS)
    args = parser.parse_args()
    try:
        if args.clipboard:
            result = {"path": clipboard_path()}
        elif args.encode:
            data, _details = read_image(args.path, args.cwd)
            result = {"data": base64.b64encode(data).decode("ascii")}
        else:
            if not args.cache:
                raise ValueError("Set --cache to a private preview directory.")
            data = remote_image(args.machine, args.path, args.cwd) if args.machine else read_image(args.path, args.cwd)[0]
            result = stage_image(data, args.cache)
        print(json.dumps(result))
    except (OSError, ValueError, subprocess.TimeoutExpired) as error:
        parser.exit(1, f"Image preview failed: {error}\n")


if __name__ == "__main__":
    main()
