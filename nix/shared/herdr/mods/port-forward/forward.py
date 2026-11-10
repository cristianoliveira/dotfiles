#!/usr/bin/env python3
"""Discover remote servers and manage owned, loopback-only SSH port forwards."""

import argparse
from contextlib import contextmanager
import fcntl
import hashlib
import ipaddress
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile
import webbrowser

OWNER = "herdr-port-forward-v1\n"


def port_number(value):
    if isinstance(value, bool) or not re.fullmatch(r"[0-9]{1,5}", str(value)):
        raise ValueError("Port must be an integer from 1 to 65535.")
    number = int(value)
    if not 1 <= number <= 65535:
        raise ValueError("Port must be from 1 to 65535.")
    return number


def ssh_target(target):
    match = re.fullmatch(r"(?:(?P<user>[A-Za-z0-9_.-]+)@)?(?P<host>\[[A-Za-z0-9:.%_-]+\]|[A-Za-z0-9_][A-Za-z0-9_.-]*)(?::(?P<port>[0-9]+))?", target)
    if not match:
        raise ValueError("Unsupported SSH target. Use an SSH host alias or user@host[:port] in hc machine add.")
    host = match["host"]
    if host.startswith("["):
        host = host[1:-1]
        ipaddress.IPv6Address(host.split("%", 1)[0])
    destination = f"{match['user']}@{host}" if match["user"] else host
    return destination, port_number(match["port"]) if match["port"] else None


def machine_list(run=subprocess.run):
    result = run(["hc", "machine", "ls", "--json"], text=True, capture_output=True, timeout=4)
    if result.returncode:
        raise ValueError("Cannot list machines. Run hc machine ls --json.")
    data = json.loads(result.stdout)
    if not isinstance(data, dict) or not isinstance(data.get("machines"), list):
        raise ValueError("Invalid machine list. Run hc machine ls --json.")
    machines = []
    for item in data["machines"]:
        if not isinstance(item, dict) or not isinstance(item.get("name"), str) or not item["name"] or item.get("temporary"):
            continue
        supported = not item.get("via") and isinstance(item.get("target"), str)
        try:
            if supported:
                ssh_target(item["target"])
        except ValueError:
            supported = False
        machines.append({**item, "supported": supported})
    return machines


def owned_directory(path):
    if path.is_symlink():
        raise ValueError(f"Refusing linked state directory: {path}")
    created = not path.exists()
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    info = path.stat()
    if info.st_uid != os.getuid() or info.st_mode & 0o077:
        raise ValueError(f"State directory must be owned by you and private (chmod 700): {path}")
    marker = path / ".owner"
    if created:
        with marker.open("x") as handle:
            handle.write(OWNER)
        marker.chmod(0o600)
    if marker.is_symlink() or not marker.is_file() or marker.read_text() != OWNER:
        raise ValueError(f"Refusing unowned state directory: {path}")


def identity(machine, target, remote_port, local_port):
    value = json.dumps([machine, target, remote_port, local_port], separators=(",", ":"))
    return hashlib.sha256(value.encode()).hexdigest()[:32]


class Manager:
    def __init__(self, root, socket_root=None, run=subprocess.run, open_url=webbrowser.open):
        self.root = Path(root)
        self.run = run
        self.open_url = open_url
        digest = hashlib.sha256(str(self.root.resolve()).encode()).hexdigest()[:8]
        self.socket_root = Path(socket_root or f"/tmp/herdr-pf-{os.getuid()}-{digest}")
        owned_directory(self.root)
        owned_directory(self.socket_root)
        self.registry = self.root / "tunnels.json"

    @contextmanager
    def locked(self):
        path = self.root / ".lock"
        descriptor = os.open(path, os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
        with os.fdopen(descriptor, "w") as handle:
            try:
                fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError as error:
                raise ValueError("Another port-forward operation is running. Retry this command shortly.") from error
            try:
                yield
            finally:
                fcntl.flock(handle, fcntl.LOCK_UN)

    def read(self):
        if not self.registry.exists():
            if self.registry.is_symlink():
                raise ValueError("Refusing linked port-forward state.")
            return []
        if self.registry.is_symlink():
            raise ValueError("Refusing linked port-forward state.")
        try:
            info = self.registry.stat()
            if not stat.S_ISREG(info.st_mode) or info.st_size > 131072:
                raise ValueError("not a bounded regular file")
            data = json.loads(self.registry.read_text())
            if (data.get("version") != 1 or not isinstance(data.get("tunnels"), list)
                    or len(data["tunnels"]) > 32):
                raise ValueError("unsupported schema")
            for item in data["tunnels"]:
                ssh_target(item["target"])
                remote = port_number(item["remote_port"])
                local = port_number(item["local_port"])
                if (not isinstance(item["machine"], str) or item.get("origin") not in ("user", "agent")
                        or item["id"] != identity(item["machine"], item["target"], remote, local)):
                    raise ValueError("invalid route")
            if len({item["id"] for item in data["tunnels"]}) != len(data["tunnels"]):
                raise ValueError("duplicate routes")
            return data["tunnels"]
        except (ValueError, KeyError, TypeError, AttributeError) as error:
            raise ValueError(f"Invalid port-forward state at {self.registry}; preserve it and inspect before retrying.") from error

    def write(self, tunnels):
        descriptor, temporary = tempfile.mkstemp(prefix=".tunnels-", dir=self.root)
        try:
            with os.fdopen(descriptor, "w") as handle:
                json.dump({"version": 1, "tunnels": tunnels}, handle)
            os.replace(temporary, self.registry)
        finally:
            Path(temporary).unlink(missing_ok=True)

    def socket(self, item):
        path = self.socket_root / item["id"]
        if len(os.fsencode(path)) >= 100:
            raise ValueError("SSH control path is too long; use a shorter --state-dir.")
        return path

    def control(self, item, operation, extra=()):
        destination, _port = ssh_target(item["target"])
        # Control clients need no SSH config: do not inherit extra forwards.
        return self.run(["ssh", "-F", "/dev/null", "-S", str(self.socket(item)), "-O", operation,
                         *extra, "--", destination], text=True, capture_output=True, timeout=3)

    def alive(self, item):
        return self.control(item, "check").returncode == 0

    def describe(self, item):
        return {**item, "state": "forwarding" if self.alive(item) else "disconnected",
                "local_url": f"http://127.0.0.1:{item['local_port']}", "application_status": "unchecked"}

    def status(self):
        with self.locked():
            return {"tunnels": [self.describe(item) for item in self.read()]}

    def start(self, machine, remote_port, local_port=None, origin="agent"):
        remote_port = port_number(remote_port)
        local_port = port_number(remote_port if local_port is None else local_port)
        if origin not in ("user", "agent"):
            raise ValueError("Origin must be user or agent.")
        machines = machine_list(self.run)
        match = next((item for item in machines if item["name"] == machine), None)
        if not match:
            raise ValueError("Unknown machine. Run hc machine ls --json, then choose its name.")
        if not match["supported"]:
            raise ValueError("This machine uses an unsupported --via/custom transport; an SSH target is required.")
        target = match["target"]
        destination, ssh_port = ssh_target(target)
        item = {"id": identity(machine, target, remote_port, local_port), "machine": machine,
                "target": target, "remote_port": remote_port, "local_port": local_port, "origin": origin}
        with self.locked():
            tunnels = self.read()
            previous = next((entry for entry in tunnels if entry["id"] == item["id"]), None)
            if previous and self.alive(previous):
                return {"tunnel": self.describe(previous), "reused": True}
            for entry in tunnels:
                if entry["id"] != item["id"] and entry["local_port"] == local_port and self.alive(entry):
                    raise ValueError(f"An existing tunnel uses local port {local_port}. Choose another --local-port.")
            if len(tunnels) >= 32 and previous is None:
                raise ValueError("32 tunnels are already recorded. Stop unused tunnels before starting more.")
            # A prior crash may have left an owned master without saved metadata.
            if self.alive(item):
                self.control(item, "exit")
                raise ValueError("Recovered an unrecorded tunnel. Retry start once its SSH master exits.")
            socket = self.socket(item)
            if socket.exists() or socket.is_symlink():
                info = socket.lstat()
                if not stat.S_ISSOCK(info.st_mode) or info.st_uid != os.getuid():
                    raise ValueError("Refusing an unexpected file at the SSH control socket path.")
                socket.unlink()
            command = ["ssh", "-M", "-N", "-T", "-f", "-S", str(socket),
                       "-o", "ControlMaster=yes", "-o", "ControlPersist=no",
                       "-o", "ClearAllForwardings=yes", "-o", "GatewayPorts=no",
                       "-o", "ForwardAgent=no", "-o", "ForwardX11=no",
                       "-o", "PermitLocalCommand=no", "-o", "LogLevel=ERROR",
                       "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=yes",
                       "-o", "ConnectTimeout=5", "-o", "ServerAliveInterval=15", "-o", "ServerAliveCountMax=2"]
            if ssh_port:
                command.extend(["-p", str(ssh_port)])
            command.extend(["--", destination])
            try:
                # A daemon may retain stderr after its parent exits: use a private
                # file, not PIPE, so waiting for SSH never waits for pipe EOF.
                with tempfile.TemporaryFile(mode="w+") as errors:
                    result = self.run(command, text=True, stdout=subprocess.DEVNULL, stderr=errors, timeout=8)
                    if result.returncode:
                        errors.seek(0)
                        detail = errors.read(4096) or result.stderr or "SSH failed"
                        recovery = ["ssh", *(["-p", str(ssh_port)] if ssh_port else []), "--", destination]
                        raise ValueError(f"SSH connection failed: {detail.strip()}. Check {shlex.join(recovery)} first.")
                result = self.control(item, "forward", ["-L", f"127.0.0.1:{local_port}:localhost:{remote_port}"])
                if result.returncode:
                    raise ValueError(f"Cannot bind local port {local_port}; choose another --local-port. {result.stderr.strip()}")
                self.write([entry for entry in tunnels if not (
                    entry["machine"] == machine and entry["remote_port"] == remote_port
                    and entry["local_port"] == local_port)] + [item])
            except (OSError, ValueError, subprocess.TimeoutExpired):
                try:
                    self.control(item, "exit")
                except (OSError, subprocess.TimeoutExpired):
                    pass
                raise
            return {"tunnel": self.describe(item), "reused": False}

    def open(self, identifier):
        with self.locked():
            item = next((entry for entry in self.read() if entry["id"] == identifier), None)
            if not item or not self.alive(item):
                raise ValueError("Choose an active tunnel from status before opening a browser.")
            url = f"http://127.0.0.1:{item['local_port']}"
        if not self.open_url(url):
            raise ValueError(f"No browser opener is available. Open {url} manually.")
        return {"local_url": url, "application_status": "unchecked"}

    def stop(self, identifier=None, machine=None, remote_port=None, local_port=None):
        if remote_port is not None:
            remote_port = port_number(remote_port)
        if local_port is not None:
            local_port = port_number(local_port)
        if not identifier and not (machine and remote_port):
            raise ValueError("Stop needs --id, or --machine and --port. Use status to see IDs.")
        with self.locked():
            tunnels = self.read()
            matches = [entry for entry in tunnels if (entry["id"] == identifier if identifier else
                       entry["machine"] == machine and entry["remote_port"] == remote_port
                       and (local_port is None or entry["local_port"] == local_port))]
            if not matches:
                return {"stopped": False}
            if len(matches) != 1:
                raise ValueError("Multiple tunnels match. Use status and stop --id <id>.")
            item = matches[0]
            if self.alive(item):
                result = self.control(item, "exit")
                if result.returncode:
                    raise ValueError("SSH could not stop the tunnel. Run status and retry stop --id " + item["id"])
            self.write([entry for entry in tunnels if entry["id"] != item["id"]])
            return {"stopped": True, "id": item["id"]}


def listening_port(address):
    host, separator, port = address.rpartition(":")
    if not separator or not port.isdigit():
        return None
    host = host.strip("[]")
    if host not in ("*", "0.0.0.0", "::", "127.0.0.1", "::1"):
        return None
    try:
        return port_number(port)
    except ValueError:
        return None


def parse_lsof(text):
    ports = {}
    process = ""
    for line in text.splitlines():
        if line.startswith("p"):
            process = ""
        elif line.startswith("c"):
            process = line[1:]
        elif line.startswith("n"):
            port = listening_port(line[1:])
            if port:
                ports.setdefault(port, {"port": port, "process": process, "address": line[1:]})
    return [ports[port] for port in sorted(ports)]


def parse_ss(text):
    ports = {}
    for line in text.splitlines():
        fields = line.split()
        port = listening_port(fields[3]) if len(fields) >= 5 else None
        if port:
            ports.setdefault(port, {"port": port, "process": "", "address": fields[3]})
    return [ports[port] for port in sorted(ports)]


def scan_local(run=subprocess.run):
    if shutil.which("lsof"):
        result = run(["lsof", "-nP", "-iTCP", "-sTCP:LISTEN", "-Fpcn"], text=True, capture_output=True, timeout=3)
        if result.returncode == 0 or (result.returncode == 1 and not result.stdout and not result.stderr):
            return {"ports": parse_lsof(result.stdout)}
    if shutil.which("ss"):
        result = run(["ss", "-H", "-ltn"], text=True, capture_output=True, timeout=3)
        if result.returncode == 0:
            return {"ports": parse_ss(result.stdout)}
    raise ValueError("Cannot discover listening ports. Install lsof or ss on that machine, or enter a port manually.")


def remote_ports(machine, run=subprocess.run):
    if not any(item["name"] == machine for item in machine_list(run)):
        raise ValueError("Unknown machine. Run hc machine ls --json.")
    source = "import sys\nsys.argv = ['forward.py', 'scan-local']\n" + Path(__file__).read_text()
    result = run(["hc", "exec", "--on", machine, "--timeout", "6", "-i", "--", "python3", "-"],
                 input=source, text=True, capture_output=True, timeout=8)
    if result.returncode:
        raise ValueError("Cannot discover ports; check remote python3/lsof/ss, or enter a port manually.")
    if len(result.stdout) > 2 * 1024 * 1024:
        raise ValueError("Remote port list exceeds 2 MiB; enter a port manually.")
    data = json.loads(result.stdout)
    if not isinstance(data, dict) or not isinstance(data.get("ports"), list):
        raise ValueError("Invalid remote port list.")
    for entry in data["ports"]:
        if (not isinstance(entry, dict) or port_number(entry.get("port")) != entry["port"]
                or not isinstance(entry.get("process"), str) or not isinstance(entry.get("address"), str)):
            raise ValueError("Invalid remote port entry.")
    return {"machine": machine, "ports": data["ports"]}


def parser():
    help_text = "Run on the computer where your browser runs. Requires existing hc, ssh and Python 3; no CLI installation."
    root = argparse.ArgumentParser(description=__doc__, epilog=help_text)
    app = Path(os.environ.get("HERDR_APP_HOME", Path.home() / ".config/herdr-app"))
    root.add_argument("--state-dir", type=Path, default=app / "data/port-forward", help="Shared private tunnel state (normally leave unchanged)")
    commands = root.add_subparsers(dest="command", required=True)
    examples = {
        "machines": ("List registered Herdr machines and SSH support", "python3 forward.py machines"),
        "list": ("Discover listening TCP ports on one machine", "python3 forward.py list --machine mac"),
        "start": ("Start or reuse a loopback-only tunnel", "python3 forward.py start --machine mac --port 3000 --local-port 3001"),
        "status": ("Show all owned tunnels and connection state (not application health)", "python3 forward.py status"),
        "stop": ("Stop an owned tunnel without killing the remote server", "python3 forward.py stop --machine mac --port 3000"),
        "scan-local": ("Inspect this computer's listening TCP ports (used for remote discovery)", "python3 forward.py scan-local"),
        "open": ("Explicitly open an owned active tunnel in the browser", "python3 forward.py open --id <id-from-status>"),
    }
    for name, (about, example) in examples.items():
        command = commands.add_parser(name, help=about, description=about, epilog=f"Example: {example}. {help_text}")
        if name in ("list", "start", "stop"):
            command.add_argument("--machine", required=name != "stop")
        if name in ("start", "stop"):
            command.add_argument("--port", required=name == "start", help="Remote loopback port, 1–65535")
            command.add_argument("--local-port", help="Local 127.0.0.1 port (start defaults to --port)")
        if name == "start":
            command.add_argument("--origin", choices=("agent", "user"), default="agent")
        if name in ("stop", "open"):
            command.add_argument("--id", required=name == "open", help="Exact tunnel ID from status")
    return root


def main():
    args = parser().parse_args()
    try:
        if args.command == "machines":
            result = {"machines": [{key: item.get(key) for key in ("name", "state", "supported")} for item in machine_list()]}
        elif args.command == "list":
            result = remote_ports(args.machine)
        elif args.command == "scan-local":
            result = scan_local()
        else:
            manager = Manager(args.state_dir)
            if args.command == "start":
                result = manager.start(args.machine, args.port, args.local_port, args.origin)
            elif args.command == "open":
                result = manager.open(args.id)
            elif args.command == "stop":
                result = manager.stop(args.id, args.machine, args.port, args.local_port)
            else:
                result = manager.status()
        print(json.dumps({"ok": True, **result}))
        return 0
    except (ValueError, OSError, subprocess.TimeoutExpired, TypeError, webbrowser.Error) as error:
        print(json.dumps({"ok": False, "error": str(error)}))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
