"""Minimal existing herdr-core framed transport; drain output, forward only user input."""
import json
import os
import select
import struct
import subprocess
import threading
import time


HEADER = struct.Struct("<IBI")
DATA, CREDIT, CLOSE = 0, 1, 2
MAX_PAYLOAD = 16 << 20


def frame(channel, kind, payload):
    if len(payload) > MAX_PAYLOAD:
        raise ValueError("Frame too large")
    return HEADER.pack(channel, kind, len(payload)) + payload


class Streams:
    def __init__(self):
        self.process = subprocess.Popen(["hc", "connect"], stdin=subprocess.PIPE,
                                        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, bufsize=0)
        self.lock = threading.Lock()
        self.channels = {}
        self.closed = False
        self.error = None
        try:
            self.process.stdin.write(b'{"jsonrpc":"2.0","id":0,"method":"hello","params":{"framed":true,"generation":1}}\n')
            reply = bytearray()
            while not reply.endswith(b"\n") and len(reply) < 65536:
                reply.extend(self.exact(1))
            if not json.loads(reply).get("result", {}).get("framed"):
                raise RuntimeError("Core does not support framed terminal streams.")
            os.set_blocking(self.process.stdin.fileno(), False)
        except Exception:
            self.close()
            raise

    def exact(self, size):
        result = bytearray()
        deadline = time.monotonic() + 5
        while len(result) < size:
            timeout = max(0, deadline - time.monotonic())
            if not select.select([self.process.stdout], [], [], timeout)[0]:
                raise RuntimeError("Core stream timed out; broadcast stopped.")
            chunk = os.read(self.process.stdout.fileno(), size - len(result))
            if not chunk:
                raise RuntimeError("Core stream disconnected; broadcast stopped.")
            result.extend(chunk)
        return bytes(result)

    def read(self):
        channel, kind, length = HEADER.unpack(self.exact(HEADER.size))
        if length > MAX_PAYLOAD:
            raise RuntimeError("Invalid core stream frame.")
        return channel, kind, self.exact(length)

    def write(self, channel, kind, payload):
        with self.lock:
            if self.closed or self.error:
                raise RuntimeError("Core stream stopped. Delivery may be partial; no retry.")
            data = memoryview(frame(channel, kind, payload))
            deadline = time.monotonic() + 1
            while data:
                if not select.select([], [self.process.stdin], [], max(0, deadline - time.monotonic()))[1]:
                    raise RuntimeError("Core stream write timed out.")
                try:
                    count = os.write(self.process.stdin.fileno(), data)
                except BlockingIOError:
                    continue
                if count <= 0:
                    raise RuntimeError("Core stream write failed.")
                data = data[count:]

    def consume(self, channel, kind, payload):
        if channel and kind == DATA:
            self.write(channel, CREDIT, struct.pack("<I", len(payload)))
        elif channel and kind == CLOSE:
            raise RuntimeError("A target stream ended; broadcast stopped.")

    def attach(self, records):
        for number, record in enumerate(records, 1):
            params = {"terminal": record["address"], "cols": record["cols"], "rows": record["rows"],
                      "history": 0, "resumed": True}
            self.write(0, DATA, json.dumps({"jsonrpc": "2.0", "id": number,
                                          "method": "terminal.attach", "params": params}).encode())
            while True:
                channel, kind, payload = self.read()
                if channel == 0 and kind == DATA:
                    reply = json.loads(payload)
                    if reply.get("id") == number:
                        if "error" in reply:
                            raise RuntimeError("Cannot attach broadcast target.")
                        self.channels[record["address"]] = reply["result"]["channel"]
                        break
                self.consume(channel, kind, payload)
        threading.Thread(target=self.drain, daemon=True).start()

    def drain(self):
        try:
            while not self.closed:
                if select.select([self.process.stdout], [], [], .1)[0]:
                    self.consume(*self.read())
        except Exception:
            if not self.closed:
                self.error = True

    def send(self, address, data):
        self.write(self.channels[address], DATA, data)

    def close(self):
        with self.lock:
            if self.closed:
                return
            self.closed = True
            if self.process.poll() is None:
                self.process.terminate()
        try:
            self.process.wait(timeout=1)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait(timeout=1)
        self.process.stdin.close()
        self.process.stdout.close()
