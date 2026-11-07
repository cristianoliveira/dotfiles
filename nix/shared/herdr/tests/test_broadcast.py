import importlib.util
import pathlib
import sys
import threading
import types
import unittest
from unittest.mock import patch

SOURCE = pathlib.Path(__file__).parents[1] / "mods/tmux-compat"
with patch.object(sys, "path", [str(SOURCE), *sys.path]):
    spec = importlib.util.spec_from_file_location("broadcast", SOURCE / "broadcast.py")
    broadcast = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(broadcast)
from broadcast_stream import Streams, frame, HEADER, DATA, CREDIT, CLOSE, MAX_PAYLOAD


class BroadcastIndicatorTests(unittest.TestCase):
    def test_ready_indicator_shows_broadcast_and_exit_key(self):
        self.assertEqual(broadcast.status_line(True, True, ""), "BROADCAST ON · Esc exits")

    def test_arming_indicator_does_not_claim_input_is_ready(self):
        self.assertEqual(broadcast.status_line(True, False, ""), "ARMING · Wait…")

    def test_stopped_indicator_reports_failure_instead_of_claiming_broadcast_is_on(self):
        self.assertEqual(broadcast.status_line(False, True, "Target stream lost"),
                         "STOPPED: Target stream lost")


class BroadcastTests(unittest.TestCase):
    def fixture(self):
        calls = []
        status = {"space": "s", "tab": "tab", "overlays": ["layout"]}
        targets = [{"pane": "p1", "terminal": "t1"}, {"pane": "p2", "terminal": "t2"}]
        records = {address: {"address": address, "state": "live", "pid": pid, "created_ms": pid}
                   for pid, address in enumerate(["t1", "t2"], 10)}
        layout = {"spaces": [{"id": "s", "tabs": [{"id": "tab", "terminals": list(targets)}]}]}

        def run(args):
            calls.append(args)
            if args[:2] == ["herdr-app", "status"]:
                return status
            if args[:2] == ["herdr-app", "ls"]:
                return layout
            if args[:2] == ["hc", "get"]:
                return records[args[-1]]
            return {}

        relay = broadcast.Relay(targets, "s", "tab", run,
                                lambda address, data: calls.append(["write", address, data]))
        relay.prepare()
        calls.clear()
        return relay, calls, status, records, layout

    def test_characters_controls_and_editing_preserve_bytes_without_implicit_enter(self):
        for char in ["a", "A", "+", "'", ";", "日", "😀", "-", " ", "\x03"]:
            self.assertEqual(broadcast.key_bytes(char), char.encode())
        self.assertEqual(broadcast.key_bytes("\n"), b"\r")
        self.assertEqual(broadcast.key_bytes("\x7f"), b"\x7f")
        self.assertIsNone(broadcast.key_bytes("\x1b"))
        self.assertEqual(broadcast.key_bytes(broadcast.curses.KEY_LEFT), b"\x1b[D")
        for unsupported in [999999, "\x16"]:
            with self.assertRaises(ValueError):
                broadcast.key_bytes(unsupported)

    def test_delivery_uses_only_frozen_targets_and_literal_input_bytes(self):
        relay, calls, *_ = self.fixture()
        data = "a日+-\r".encode()

        relay.deliver(data)

        self.assertEqual([call for call in calls if call[0] == "write"], [
            ["write", "t1", data], ["write", "t2", data],
        ])

    def test_successive_batches_keep_order_without_duplicate_input(self):
        relay, calls, *_ = self.fixture()

        relay.deliver(b"ab")
        relay.deliver(b"cd")

        for address in ["t1", "t2"]:
            self.assertEqual(b"".join(call[2] for call in calls if call[:2] == ["write", address]), b"abcd")

    def test_context_or_target_changes_stop_before_any_delivery(self):
        for change in ["tab", "space", "overlay", "pane", "pid", "finished"]:
            with self.subTest(change=change):
                relay, calls, status, records, layout = self.fixture()
                if change in ("tab", "space"):
                    status[change] = "other"
                elif change == "overlay":
                    status["overlays"].append("other-dialog")
                elif change == "pane":
                    layout["spaces"][0]["tabs"][0]["terminals"].pop()
                elif change == "pid":
                    records["t2"]["pid"] = 100
                else:
                    records["t2"]["state"] = "finished"

                with self.assertRaises(RuntimeError):
                    relay.deliver(b"\r")

                self.assertFalse(any(call[0] == "write" for call in calls))
                self.assertFalse(relay.active)

    def test_partial_failure_stops_without_retry_or_later_input(self):
        relay, calls, *_ = self.fixture()
        original = relay.send

        def fail_second(address, data):
            original(address, data)
            if address == "t2":
                raise RuntimeError("disconnected")
        relay.send = fail_second

        with self.assertRaises(RuntimeError):
            relay.deliver(b"x")
        relay.deliver(b"\r")

        self.assertEqual(len([call for call in calls if call[0] == "write"]), 2)
        self.assertFalse(relay.active)

    def test_exit_cancels_unsent_targets(self):
        relay, calls, *_ = self.fixture()
        original = relay.send

        def stop_after_first(address, data):
            original(address, data)
            relay.stop()
        relay.send = stop_after_first

        relay.deliver(b"x")

        self.assertEqual([call[1] for call in calls if call[0] == "write"], ["t1"])

    def test_invalid_duplicate_or_remote_targets_are_rejected(self):
        for targets in [[], [{"pane": "p", "terminal": "host/t1"}],
                        [{"pane": "p", "terminal": "t1"}] * 2]:
            with self.assertRaises(ValueError):
                broadcast.Relay(targets, "s", "tab", lambda _: {}, lambda *_: None)

    def test_framing_uses_existing_core_little_endian_protocol(self):
        self.assertEqual(frame(7, DATA, b"xy"), b"\x07\0\0\0\0\x02\0\0\0xy")
        streams = Streams.__new__(Streams)
        pieces = [HEADER.pack(3, DATA, 2), b"ok"]
        streams.exact = lambda _: pieces.pop(0)
        self.assertEqual(streams.read(), (3, DATA, b"ok"))

    def test_output_only_replenishes_credit_and_is_never_broadcast_as_input(self):
        streams = Streams.__new__(Streams)
        sent = []
        streams.write = lambda *args: sent.append(args)

        streams.consume(4, DATA, b"terminal output")

        self.assertEqual(sent, [(4, CREDIT, b"\x0f\0\0\0")])
        with self.assertRaises(RuntimeError):
            streams.consume(4, CLOSE, b"{}")

    def test_startup_waits_for_overlay_without_typing_and_has_a_deadline(self):
        relay, calls, status, *_ = self.fixture()
        status["overlays"] = []
        def install_overlay(_):
            status["overlays"] = ["layout"]

        relay.prepare(wait=install_overlay, now=lambda: 0)

        self.assertFalse(any(call[0] == "write" for call in calls))
        status["overlays"] = []
        clock = iter([0, 6])
        with self.assertRaises(RuntimeError):
            relay.prepare(now=lambda: next(clock))

    def test_blocked_stream_writer_times_out_instead_of_blocking_exit(self):
        streams = Streams.__new__(Streams)
        streams.lock = threading.Lock()
        streams.closed = False
        streams.error = None
        streams.process = types.SimpleNamespace(stdin=object())

        with patch("broadcast_stream.select.select", return_value=([], [], [])):
            with self.assertRaisesRegex(RuntimeError, "timed out"):
                streams.write(1, DATA, b"x")

    def test_oversized_frames_are_refused_before_payload_read(self):
        streams = Streams.__new__(Streams)
        streams.exact = lambda _: HEADER.pack(3, DATA, MAX_PAYLOAD + 1)

        with self.assertRaises(RuntimeError):
            streams.read()
