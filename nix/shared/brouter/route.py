#!/usr/bin/env python3
"""Select brouter targets from the original URL bytes."""

from datetime import datetime, time
import re
import sys
from urllib.parse import urlsplit


PERSONAL = re.compile(
    # Joy
    rb"ycombinator\.com|youtube\.com|x\.com|reddit\.com|"
    rb"instagram\.com"
    rb"openai\.com"
    rb"$"
)
WORK = re.compile(
    rb"github\.com/(wireapp|pydio)|"

    rb"meet\.google|atlassian.net|ngrok-free|tuple|figma|smartling|"
    rb"sentry.io|expo.dev|mail.google|mixpanel\.com|miro\.com|"
    rb"segment\.com|sanity.studio|superblocks|slack|notion.so|docs\.google|"
    # Storage
    rb"drive\.google\.com|"

    # wire
    rb"shortcut\.com|jumpcloud.com|"
    rb"wire\.com|pydio\.com|zendesk\.com"
    rb"$"
)
DEV = re.compile(
    rb"localhost|local\.gd|"

    # Other development patterns retain their existing raw URL matching.
    rb"local\.zinfra\.io"
)
WORK_START = time(7, 0)
WORK_END = time(18, 0)

def is_working_hours(now: datetime) -> bool:
    """Return whether a local Mac datetime is within the work window."""
    return now.weekday() < 5 and WORK_START <= now.time() < WORK_END


def is_wire_link_host(url: bytes) -> bool:
    """Match wire.link by hostname, independent of port, path, or case."""
    try:
        hostname = urlsplit(url).hostname
    except ValueError:
        return False
    return hostname == b"wire.link" or (
        hostname is not None and hostname.endswith(b".wire.link")
    )


def choose_target(url: bytes, now: datetime) -> bytes:
    """Choose a target without reading the clock or stdin."""
    if PERSONAL.search(url) is not None:
        return b"personal"

    is_work_url = WORK.search(url) is not None
    if is_work_url and is_working_hours(now):
        return b"work"

    is_dev_url = DEV.search(url) is not None or is_wire_link_host(url)
    if is_dev_url:
        return b"dev"

    return b"@default"


def main() -> None:
    url = sys.stdin.buffer.read()
    if url.endswith(b"\n"):
        url = url[:-1]
    sys.stdout.buffer.write(choose_target(url, datetime.now()) + b"\n")


if __name__ == "__main__":
    main()
