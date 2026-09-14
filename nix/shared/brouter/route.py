#!/usr/bin/env python3
"""Select brouter targets from the original URL bytes."""

from datetime import datetime, time
import re
import sys


WORK = re.compile(
    rb"meet\.google|atlassian.net|ngrok-free|tuple|figma|smartling|"
    rb"sentry.io|expo.dev|mail.google|github\.com|mixpanel\.com|miro\.com|"
    rb"segment\.com|sanity.studio|superblocks|slack|notion.so|docs\.google|"

    # wire
    rb"shortcut\.com|jumpcloud.com|"
    rb"wire\.com|pydio.com|zendesk\.com"
)
DEV = re.compile(
    rb"localhost|local.gd|"

    # wire
    rb"local.zinfra.io|wire.link|"
)
WORK_START = time(7, 0)
WORK_END = time(18, 0)

def is_working_hours(now: datetime) -> bool:
    """Return whether a local Mac datetime is within the work window."""
    return now.weekday() < 5 and WORK_START <= now.time() < WORK_END


def choose_target(url: bytes, now: datetime) -> bytes:
    """Choose a target without reading the clock or stdin."""
    is_work_url = WORK.search(url) is not None
    is_dev_url = DEV.search(url) is not None

    if is_work_url and is_working_hours(now):
        return b"work"
    if is_dev_url:
        return b"dev"
    if is_work_url:
        return b"personal"
    return b"@default"


def main() -> None:
    url = sys.stdin.buffer.read()
    if url.endswith(b"\n"):
        url = url[:-1]
    sys.stdout.buffer.write(choose_target(url, datetime.now()) + b"\n")


if __name__ == "__main__":
    main()
