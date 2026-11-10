function portNumber(value) {
  const text = String(value).trim();
  const number = Number(text);
  if (!/^[0-9]{1,5}$/.test(text) || number < 1 || number > 65535) {
    throw new Error("Choose a port from 1 to 65535.");
  }
  return number;
}

export function startArgs(machine, remote, local) {
  if (!machine) throw new Error("Choose a remote machine first.");
  const port = portNumber(remote);
  const localPort = String(local).trim() ? portNumber(local) : port;
  return ["start", "--machine", machine, "--port", String(port), "--local-port", String(localPort), "--origin", "user"];
}

export function matchingTunnel(tunnels, machine, remote, local) {
  try {
    const args = startArgs(machine, remote, local);
    return tunnels.find(tunnel => tunnel.machine === machine
      && tunnel.remote_port === Number(args[4]) && tunnel.local_port === Number(args[6])) ?? null;
  } catch {
    return null;
  }
}
