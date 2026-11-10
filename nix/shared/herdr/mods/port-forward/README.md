# Port Forward

Select a server on another Herdr machine and reach it through this computer's
loopback interface. The popup and agent helper share the same tunnel state.
No separate CLI, package, or remote mod installation is needed.

## Popup workflow

1. Open **Ctrl-a t** (holding Ctrl for both keys also works).
2. Choose a machine. The focused remote space is selected by default; from a
   local space, the first connected, SSH-supported machine is selected.
3. Select a discovered listening port, or type a remote port manually.
4. Leave Local empty to use the same port, or enter a different local port.
5. Press **Enter** or **Forward**. An owned-tunnel row shows the resulting URL.
6. **Browser** explicitly opens an HTTP URL. It is never opened automatically.
7. Press **Stop** to end that tunnel. The remote server keeps running.

↑/↓ or Ctrl-j/k select discovered ports. **Refresh** checks machines and ports
again. **Esc** closes the popup but leaves tunnels running. Agent-created
tunnels appear in the same list; connection state refreshes every five seconds
while the popup is open. Disconnected tunnels have a **Reconnect** action.

Discovery reports TCP listeners bound to remote loopback or wildcard addresses.
It does not prove they are web servers. Discovery failure does not prevent
manual forwarding. A machine without a `lsof` or `ss` executable can still be
forwarded manually.

## Agent workflow: no CLI installation

Run the bundled Python file **on the computer where the browser runs**:

```sh
python3 ~/.config/herdr-app/mods/port-forward/forward.py machines
python3 ~/.config/herdr-app/mods/port-forward/forward.py list --machine mac
python3 ~/.config/herdr-app/mods/port-forward/forward.py start --machine mac --port 3000
python3 ~/.config/herdr-app/mods/port-forward/forward.py status
python3 ~/.config/herdr-app/mods/port-forward/forward.py stop --machine mac --port 3000
```

Choose another local port when the default is occupied:

```sh
python3 ~/.config/herdr-app/mods/port-forward/forward.py start \
  --machine mac --port 3000 --local-port 3001
```

Operations print JSON and fail with a nonzero exit status and `ok: false`.
`start` returns `tunnel.id`, `local_url`, connection `state`, and `reused`.
Repeated starts reuse the matching active tunnel. New helper-created tunnels
have origin `agent`; popup-created tunnels have origin `user`. Reusing an
existing tunnel does not change its origin.

A successful tunnel has `state: "forwarding"`, but always reports
`application_status: "unchecked"`. Wait for the remote server to become ready
and separately check the application before telling the user it is ready.
Do not claim that an SSH connection proves application health.

Use IDs to stop an exact tunnel or open it in a browser explicitly:

```sh
python3 ~/.config/herdr-app/mods/port-forward/forward.py stop --id ID_FROM_STATUS
python3 ~/.config/herdr-app/mods/port-forward/forward.py open --id ID_FROM_STATUS
```

### Agents running on a remote machine

Running the helper on Mac creates a listener on Mac, not on this desktop.
Instead, invoke the desktop helper through an existing reverse Herdr route.
The current Mac already knows this desktop as `nixos`:

```sh
hc exec --on nixos -- python3 \
  /home/cristianoliveira/.config/herdr-app/mods/port-forward/forward.py \
  start --machine mac --port 3000
```

That uses only existing `hc` and Python. The helper stays installed on the
desktop. Use the desktop's actual alias/path on other setups; tilde arguments
are not expanded by `hc exec`. If there is no existing route to the desktop,
ask a local agent to run the helper; do not silently create a tunnel on the
wrong computer or add machine registrations/authentication.

## Safety and lifecycle

- Every listener binds **127.0.0.1**, never a LAN address or wildcard.
- Remote destinations are fixed to **localhost**; forwarding arbitrary remote
  networks is not supported. All TCP services can be forwarded, not just HTTP.
- Browser URLs assume plain HTTP; for HTTPS or non-HTTP services, use the
  appropriate client yourself. The tunnel does not terminate TLS.
- The helper takes targets from `hc machine ls`, reuses SSH configuration for
  identity/proxy settings, and parses custom SSH ports and bracketed IPv6.
- Custom `--via` transports are rejected rather than guessed.
- SSH must already authenticate non-interactively. Host-key verification stays
  enabled. The helper never adds keys, passwords, or host trust.
- Each tunnel uses a separate, private SSH control master. Inherited SSH
  forwards are cleared before adding the single requested loopback forward.
  GatewayPorts, SSH agent forwarding, X11 forwarding, and LocalCommand execution
  are explicitly disabled.
- An occupied local port produces an error. No unrelated process is killed and
  no alternate local port is silently chosen.
- Stop uses the owned control socket, never a saved PID or `pkill`. It does not
  affect unrelated SSH sessions, agents, or remote servers.
- Closing Herdr does not stop established tunnels. Network failure eventually
  closes SSH after its keepalive checks; the UI shows Disconnected. Reconnect
  is explicit; no hidden reconnect loop or reboot auto-start is installed.
- Registry: `~/.config/herdr-app/data/port-forward/`, private 0700 directory and
  0600 JSON/lock files. Records remain until stopped, including disconnected
  ones, so they stay manageable. At most 32 routes are recorded.
- Short control sockets live in a private, ownership-marked `/tmp/herdr-pf-*`
  directory. The app-home path distinguishes separate app installations.
- State operations use a nonblocking file lock. Concurrent commands can return
  a busy error; retry them rather than changing or deleting state.

Supports Linux/NixOS and macOS clients (Unix control sockets and file locking).
Requires existing `ssh`, `hc`, and Python 3 on this computer. Discovery also
requires Python 3 and `lsof` or `ss` remotely. There are no new dependencies.
Machine listing is bounded at four seconds, remote discovery at six seconds
(server) / eight seconds (client), SSH connection at five seconds with an
eight-second launcher timeout, and local control operations at three seconds.

## Verify

```sh
python3 -m unittest discover -s nix/shared/herdr/tests -p test_port_forward.py
node --experimental-default-type=module --test nix/shared/herdr/tests/port-forward-*.test.mjs
herdr-app check ~/.config/herdr-app/mods/port-forward
herdr-app do mod.open:port-forward
```
