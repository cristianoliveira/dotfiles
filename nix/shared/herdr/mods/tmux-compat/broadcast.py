#!/usr/bin/env python3
"""Opt-in keyboard proxy for a frozen set of local Herdr tab panes."""
import argparse
import curses
import json
import os
import queue
import re
import subprocess
import sys
import threading
import time

from broadcast_stream import Streams


NAMED_KEYS = {
    curses.KEY_LEFT: b"\x1b[D", curses.KEY_RIGHT: b"\x1b[C", curses.KEY_UP: b"\x1b[A",
    curses.KEY_DOWN: b"\x1b[B", curses.KEY_HOME: b"\x1b[H", curses.KEY_END: b"\x1b[F",
    curses.KEY_DC: b"\x1b[3~", curses.KEY_BACKSPACE: b"\x7f",
    curses.KEY_PPAGE: b"\x1b[5~", curses.KEY_NPAGE: b"\x1b[6~", curses.KEY_BTAB: b"\x1b[Z",
    curses.KEY_ENTER: b"\r",
}


def key_bytes(value):
    if value == "\x1b":
        return None
    if isinstance(value, int):
        if value in NAMED_KEYS:
            return NAMED_KEYS[value]
        raise ValueError("Unsupported key; broadcast stopped. Escape exits.")
    if len(value) != 1:
        raise ValueError("Unsupported text input; broadcast stopped.")
    if value == "\x16":
        raise ValueError("Paste is unsupported in this prototype; broadcast stopped.")
    return {"\n": b"\r", "\b": b"\x7f"}.get(value, value.encode("utf-8"))


class Relay:
    def __init__(self, targets, space, tab, run, send):
        addresses = [target.get("terminal", "") for target in targets]
        if not 2 <= len(targets) <= 8 or len(set(addresses)) != len(addresses) or any(
                not re.fullmatch(r"t[a-z0-9]+", address) for address in addresses):
            raise ValueError("Broadcast needs 2–8 distinct local terminal panes.")
        self.targets = targets
        self.space, self.tab, self.run, self.send = space, tab, run, send
        self.active = True
        self.pins = {}

    def identity(self, address):
        record = self.run(["hc", "get", "--json", address])
        if record.get("address") != address or record.get("state") != "live" or not record.get("pid"):
            raise RuntimeError("A target terminal is no longer live. Broadcast stopped.")
        return record["pid"], record["created_ms"]

    def prepare(self, wait=time.sleep, now=time.monotonic):
        # The program may start before its native overlay has been installed.
        deadline = now() + 5
        while self.active:
            status = self.run(["herdr-app", "status"])
            if (status.get("space"), status.get("tab")) != (self.space, self.tab):
                raise RuntimeError("Window context changed before broadcast was ready.")
            if status.get("overlays") == ["layout"]:
                break
            if status.get("overlays") or now() >= deadline:
                raise RuntimeError("Broadcast overlay did not become available.")
            wait(.05)
        if not self.active:
            raise RuntimeError("Broadcast closed during startup.")
        self.pins = {target["terminal"]: self.identity(target["terminal"]) for target in self.targets}
        self.verify_scope()

    def verify_scope(self):
        status = self.run(["herdr-app", "status"])
        if (status.get("space"), status.get("tab"), status.get("overlays")) != (self.space, self.tab, ["layout"]):
            raise RuntimeError("Window context changed. Broadcast stopped.")
        layout = self.run(["herdr-app", "ls"])
        tab = next((tab for space in layout.get("spaces", []) if space["id"] == self.space
                    for tab in space["tabs"] if tab["id"] == self.tab), {})
        current = tab.get("terminals", [])
        pairs = {(item.get("pane"), item.get("terminal")) for item in current}
        if (any((target["pane"], target["terminal"]) not in pairs for target in self.targets)
                or {item.get("terminal") for item in current} != set(self.pins)):
            raise RuntimeError("Tab panes changed. Broadcast stopped; reopen to review targets.")

    def stop(self):
        self.active = False

    def deliver(self, data):
        if not self.active:
            return
        try:
            self.verify_scope()
            for address, identity in self.pins.items():
                if self.identity(address) != identity:
                    raise RuntimeError("A target program restarted. Broadcast stopped.")
            for target in self.targets:
                if not self.active:
                    return
                self.send(target["terminal"], data)
        except Exception:
            self.stop()
            raise


class Commands:
    def __init__(self, app_home):
        self.env = dict(os.environ, HERDR_APP_HOME=app_home)
        self.lock = threading.Lock()
        self.children = set()
        self.closed = False

    def __call__(self, args):
        with self.lock:
            if self.closed:
                raise RuntimeError("Broadcast closed.")
            process = subprocess.Popen(args, env=self.env, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            self.children.add(process)
        try:
            out, _ = process.communicate(timeout=5)
            if process.returncode:
                raise RuntimeError("Target check failed. Broadcast stopped; Escape exits.")
            return json.loads(out)
        except subprocess.TimeoutExpired:
            process.kill()
            process.communicate()
            raise RuntimeError("Target check timed out. Broadcast stopped; Escape exits.") from None
        finally:
            with self.lock:
                self.children.discard(process)

    def close(self):
        with self.lock:
            self.closed = True
            for process in self.children:
                if process.poll() is None:
                    process.terminate()


def status_line(active, ready, message):
    if not active:
        return "STOPPED: " + message
    if not ready:
        return "ARMING · Wait…"
    return "BROADCAST ON · Esc exits"


def interface(screen, relay, commands, streams):
    curses.raw()
    curses.noecho()
    curses.set_escdelay(25)
    screen.keypad(True)
    screen.timeout(50)
    # Paste starts with Escape, which exits before pasted newlines can be relayed.
    sys.stdout.write("\033[?2004h")
    sys.stdout.flush()
    pending = queue.Queue(maxsize=128)
    state = {"ready": False, "message": "Arming targets… wait for READY before typing."}

    def worker():
        try:
            relay.prepare()
            records = [commands(["hc", "get", "--json", target["terminal"]]) for target in relay.targets]
            streams.attach(records)
            for record in records:
                if relay.identity(record["address"]) != relay.pins[record["address"]]:
                    raise RuntimeError("Target restarted during setup. Broadcast stopped.")
            state.update(ready=True, message="READY · Enter runs in ALL. Esc exits.")
            while relay.active:
                try:
                    keys = [pending.get(timeout=.1)]
                except queue.Empty:
                    continue
                while len(keys) < 32:
                    try:
                        keys.append(pending.get_nowait())
                    except queue.Empty:
                        break
                relay.deliver(b"".join(keys))
        except Exception as error:
            relay.stop()
            streams.close()
            state["message"] = str(error)

    threading.Thread(target=worker, daemon=True).start()
    try:
        while True:
            if streams.error and relay.active:
                relay.stop()
                state["message"] = "Target stream lost. Delivery may be partial; no retry. Escape exits."
                streams.close()
            screen.erase()
            _, width = screen.getmaxyx()
            line = status_line(relay.active, state["ready"], state["message"])
            screen.addnstr(0, 0, line, max(0, width - 1))
            screen.refresh()
            try:
                value = screen.get_wch()
            except curses.error:
                continue
            if value == curses.KEY_RESIZE:
                continue
            try:
                key = key_bytes(value)
                if key is None:
                    return
                if state["ready"] and relay.active:
                    pending.put_nowait(key)
            except (ValueError, queue.Full) as error:
                relay.stop()
                state["message"] = str(error) or "Input queue full. Broadcast stopped; Escape exits."
    finally:
        relay.stop()
        streams.close()
        commands.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__,
        epilog="Start from Herdr with: herdr-app do tmux-compat.broadcast (requires 2–8 local tab panes).")
    parser.add_argument("--targets", required=True, type=json.loads)
    parser.add_argument("--space", required=True)
    parser.add_argument("--tab", required=True)
    parser.add_argument("--app-home", required=True)
    args = parser.parse_args()
    commands = Commands(args.app_home)
    streams = Streams()
    relay = Relay(args.targets, args.space, args.tab, commands, streams.send)
    os.environ["TERM"] = "xterm-256color"
    try:
        curses.wrapper(interface, relay, commands, streams)
    finally:
        streams.close()
        commands.close()
        sys.stdout.write("\033[?2004l")
        sys.stdout.flush()


if __name__ == "__main__":
    main()
