import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "mods/port-forward/forward.py"
SPEC = importlib.util.spec_from_file_location("port_forward", SCRIPT)
forward = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(forward)


class Transport:
    def __init__(self):
        self.calls = []
        self.masters = set()
        self.fail_forward = False

    def __call__(self, argv, **options):
        self.calls.append(argv)
        if argv[:3] == ["hc", "machine", "ls"]:
            return subprocess.CompletedProcess(argv, 0, json.dumps({"machines": [
                {"name": "mac", "target": "me@mac.test:2222", "state": "connected", "via": False},
                {"name": "sandbox", "target": "arbitrary command", "state": "connected", "via": True},
            ]}), "")
        control = argv[argv.index("-S") + 1]
        if "-O" in argv:
            operation = argv[argv.index("-O") + 1]
            if operation == "exit":
                self.masters.discard(control)
                return subprocess.CompletedProcess(argv, 0, "", "")
            if operation == "forward":
                return subprocess.CompletedProcess(argv, int(self.fail_forward), "", "port occupied" if self.fail_forward else "")
            return subprocess.CompletedProcess(argv, 0 if control in self.masters else 255, "", "")
        self.masters.add(control)
        return subprocess.CompletedProcess(argv, 0, "", "")


class PortForwardTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.transport = Transport()
        self.manager = forward.Manager(self.root / "state", socket_root=self.root / "sockets", run=self.transport)

    def test_start_requests_loopback_only_and_disables_inherited_forwards(self):
        result = self.manager.start("mac", 3000, 3001, "agent")

        self.assertEqual(result["tunnel"]["state"], "forwarding")
        self.assertEqual(result["tunnel"]["local_url"], "http://127.0.0.1:3001")
        self.assertEqual(result["tunnel"]["application_status"], "unchecked")
        master = next(call for call in self.transport.calls if "-M" in call)
        self.assertIn("ClearAllForwardings=yes", master)
        self.assertIn("GatewayPorts=no", master)
        self.assertIn("ForwardAgent=no", master)
        self.assertIn("ForwardX11=no", master)
        self.assertIn("StrictHostKeyChecking=yes", master)
        self.assertIn("BatchMode=yes", master)
        self.assertEqual(master[-1], "me@mac.test")
        self.assertEqual(master[master.index("-p") + 1], "2222")
        request = next(call for call in self.transport.calls if "forward" in call)
        self.assertEqual(request[request.index("-L") + 1], "127.0.0.1:3001:localhost:3000")
        self.assertEqual(request[request.index("-F") + 1], "/dev/null")

    def test_repeated_start_reuses_tunnel_and_status_is_shared_between_invocations(self):
        first = self.manager.start("mac", 3000, 3000, "user")
        second = self.manager.start("mac", 3000, 3000, "agent")
        other = forward.Manager(self.root / "state", socket_root=self.root / "sockets", run=self.transport)

        self.assertFalse(first["reused"])
        self.assertTrue(second["reused"])
        self.assertEqual(sum("-M" in call for call in self.transport.calls), 1)
        self.assertEqual(other.status()["tunnels"][0]["origin"], "user")
        self.assertEqual(other.status()["tunnels"][0]["id"], first["tunnel"]["id"])

    def test_stop_controls_only_owned_master_and_is_idempotent(self):
        started = self.manager.start("mac", 3000, 3000, "user")
        identifier = started["tunnel"]["id"]

        self.assertTrue(self.manager.stop(identifier=identifier)["stopped"])
        self.assertFalse(self.manager.stop(identifier=identifier)["stopped"])
        self.assertEqual(self.manager.status()["tunnels"], [])
        self.assertEqual(self.transport.masters, set())

    def test_failed_forward_stops_new_master_and_does_not_record_success(self):
        self.transport.fail_forward = True

        with self.assertRaisesRegex(ValueError, "local-port"):
            self.manager.start("mac", 3000, 3000, "agent")

        self.assertEqual(self.transport.masters, set())
        self.assertEqual(self.manager.status()["tunnels"], [])

    def test_lost_connection_is_reported_and_start_reconnects(self):
        self.manager.start("mac", 3000, 3000, "user")
        self.transport.masters.clear()

        self.assertEqual(self.manager.status()["tunnels"][0]["state"], "disconnected")
        self.assertFalse(self.manager.start("mac", 3000, 3000, "user")["reused"])
        self.assertEqual(self.manager.status()["tunnels"][0]["state"], "forwarding")

    def test_invalid_ports_unknown_machines_and_via_commands_are_rejected(self):
        for port in [0, 65536, "3000; touch NEVER", True, 3.5]:
            with self.subTest(port=port), self.assertRaises(ValueError):
                self.manager.start("mac", port, 3000, "agent")
        for machine in ["unknown", "sandbox"]:
            with self.subTest(machine=machine), self.assertRaises(ValueError):
                self.manager.start(machine, 3000, 3000, "agent")
        self.assertFalse(any("-M" in call for call in self.transport.calls))

    def test_local_port_conflict_between_owned_tunnels_preserves_the_existing_tunnel(self):
        self.manager.start("mac", 3000, 3000, "user")

        with self.assertRaisesRegex(ValueError, "local port"):
            self.manager.start("mac", 5173, 3000, "agent")

        self.assertEqual(len(self.manager.status()["tunnels"]), 1)
        self.assertEqual(len(self.transport.masters), 1)

    def test_private_state_and_corrupt_registry_are_not_silently_overwritten(self):
        self.manager.start("mac", 3000, 3000, "agent")
        path = self.root / "state/tunnels.json"
        self.assertEqual(path.stat().st_mode & 0o777, 0o600)
        path.write_text("not json")

        with self.assertRaisesRegex(ValueError, "state"):
            self.manager.status()
        self.assertEqual(path.read_text(), "not json")

    def test_ssh_target_validation_preserves_port_and_ipv6_without_accepting_options(self):
        self.assertEqual(forward.ssh_target("me@host.test:2222"), ("me@host.test", 2222))
        self.assertEqual(forward.ssh_target("me@[::1]:2222"), ("me@::1", 2222))
        for target in ["-oProxyCommand=bad", "host;touch NEVER", "ssh me@host", "host:99999"]:
            with self.subTest(target=target), self.assertRaises(ValueError):
                forward.ssh_target(target)

    def test_lsof_and_ss_discovery_only_return_ports_reachable_via_remote_loopback(self):
        lsof = "p1\ncnode\nn127.0.0.1:3000\nn*:3000\np2\ncserver\nn[::1]:5173\nn192.168.1.2:9000\n"
        ports = forward.parse_lsof(lsof)
        self.assertEqual([item["port"] for item in ports], [3000, 5173])
        self.assertEqual(ports[0]["process"], "node")
        ss = "LISTEN 0 128 0.0.0.0:3000 0.0.0.0:*\nLISTEN 0 128 [::1]:5173 [::]:*\n"
        self.assertEqual([item["port"] for item in forward.parse_ss(ss)], [3000, 5173])

    def test_browser_open_is_explicit_and_only_uses_an_owned_loopback_url(self):
        opened = []
        manager = forward.Manager(self.root / "state", socket_root=self.root / "sockets",
                                  run=self.transport, open_url=lambda url: opened.append(url) or True)
        result = manager.start("mac", 3000, 3001)
        self.assertEqual(opened, [])

        manager.open(result["tunnel"]["id"])
        self.assertEqual(opened, ["http://127.0.0.1:3001"])
        with self.assertRaises(ValueError):
            manager.open("not-owned")

    def test_simultaneous_command_reports_busy_instead_of_racing_state(self):
        with self.manager.locked():
            with self.assertRaisesRegex(ValueError, "operation is running"):
                self.manager.status()

    def test_unowned_or_linked_state_directory_is_refused(self):
        unowned = self.root / "unowned"
        unowned.mkdir(mode=0o700)
        linked = self.root / "linked"
        linked.symlink_to(self.root / "state", target_is_directory=True)
        for path in (unowned, linked):
            with self.subTest(path=path), self.assertRaises(ValueError):
                forward.Manager(path, socket_root=self.root / "sockets", run=self.transport)

    def test_ambiguous_stop_requires_an_exact_id(self):
        self.manager.start("mac", 3000, 3001)
        self.manager.start("mac", 3000, 3002)

        with self.assertRaisesRegex(ValueError, "Multiple tunnels"):
            self.manager.stop(machine="mac", remote_port=3000)
        self.assertEqual(len(self.manager.status()["tunnels"]), 2)

    def test_remote_scanner_source_runs_without_installing_helper_there(self):
        import os
        import shutil

        def run(argv, **options):
            if argv[:3] == ["hc", "machine", "ls"]:
                return self.transport(argv, **options)
            return subprocess.CompletedProcess(argv, 0, '{"ports":[{"port":3000,"process":"node","address":"*:3000"}]}', "")

        result = forward.remote_ports("mac", run=run)
        self.assertEqual(result["ports"][0]["port"], 3000)
        # Run the actual transmitted scanner locally; mock only executable lookup
        # via a tiny ss fixture, not the parser or generated Python source.
        scanner = self.root / "ss"
        scanner.write_text(chr(10).join(["#!/bin/sh", "echo 'LISTEN 0 128 127.0.0.1:3000 0.0.0.0:*'", ""]))
        scanner.chmod(0o700)
        python = shutil.which("python3")

        def execute(argv, **options):
            if argv[:3] == ["hc", "machine", "ls"]:
                return self.transport(argv, **options)
            return subprocess.run([python, "-"], input=options["input"], text=True, capture_output=True,
                                  env={**os.environ, "PATH": str(self.root)}, timeout=5)

        self.assertEqual(forward.remote_ports("mac", run=execute)["ports"][0]["port"], 3000)

    def test_auth_failure_reports_exact_ssh_recovery_command_without_recording_tunnel(self):
        def denied(argv, **options):
            if "-M" in argv:
                return subprocess.CompletedProcess(argv, 255, "", "Permission denied")
            return self.transport(argv, **options)
        self.manager.run = denied

        with self.assertRaisesRegex(ValueError, "ssh -p 2222 -- me@mac.test"):
            self.manager.start("mac", 3000)
        self.assertEqual(self.manager.status()["tunnels"], [])

    def test_connection_timeout_attempts_owned_master_cleanup(self):
        def timeout(argv, **options):
            if "-M" in argv:
                raise subprocess.TimeoutExpired(argv, options["timeout"])
            return self.transport(argv, **options)
        self.manager.run = timeout

        with self.assertRaises(subprocess.TimeoutExpired):
            self.manager.start("mac", 3000)
        self.assertTrue(any("exit" in call for call in self.transport.calls))
        self.assertEqual(self.manager.status()["tunnels"], [])

    def test_stop_does_not_require_machine_discovery(self):
        started = self.manager.start("mac", 3000)
        count = sum(call[:3] == ["hc", "machine", "ls"] for call in self.transport.calls)

        self.manager.stop(identifier=started["tunnel"]["id"])

        self.assertEqual(sum(call[:3] == ["hc", "machine", "ls"] for call in self.transport.calls), count)

    def test_cli_errors_are_json_and_have_nonzero_exit_status(self):
        result = subprocess.run(["python3", str(SCRIPT), "start", "--machine", "mac", "--port", "not-a-port"],
                                text=True, capture_output=True, timeout=5)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(json.loads(result.stdout)["ok"])


if __name__ == "__main__":
    unittest.main()
