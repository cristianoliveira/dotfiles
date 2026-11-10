import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";
import { startArgs, matchingTunnel } from "../mods/port-forward/model.js";

function element() {
  const node = { handlers: {}, children: [] };
  const builder = new Proxy(node, { get(target, name) {
    if (name === "child") return child => { target.children.push(child); return builder; };
    if (name === "children") return children => { target.children.push(...children); return builder; };
    if (name in target) return target[name];
    if (name === "when") return (condition, apply) => condition ? apply(builder) : builder;
    return (...args) => { target.handlers[name] = args; return builder; };
  } });
  return builder;
}

async function popup({ discoverError = false, startError = "" } = {}) {
  const path = new URL("../mods/port-forward/main.js", import.meta.url);
  const source = (await readFile(path, "utf8")).replace(/^import .*;$/gm, "")
    .replace("export default class PortForward", "globalThis.Forward = class PortForward");
  const calls = [], tasks = [], timers = [], closed = [];
  const backend = { tunnels: [] };
  const scope = {
    View: class {}, div: element, v_flex: element, h_flex: element, v_virtual_list: element,
    Input: { new: element }, InputState: { new: () => {
      let value = "";
      const handlers = {};
      return { value: () => value, set_value: next => { value = next; }, on: (name, callback) => { handlers[name] = callback; }, focus() {}, handlers };
    } },
    VirtualListScrollHandle: { new: () => ({ scroll_to_item() {} }) },
    startArgs, matchingTunnel, focused: () => ({ space: "remote" }),
    spaces: () => [{ id: "remote", machine: "mac" }], appHome: () => "/app", theme: () => ({}),
    props: () => ({ overlay: "forward" }), closeOverlay: id => closed.push(id),
    exec: async (_command, argv) => {
      const args = Array.from(argv).slice(3);
      calls.push(args);
      let data = { ok: true };
      if (args[0] === "machines") data.machines = [{ name: "mac", state: "connected", supported: true }];
      if (args[0] === "list") data = discoverError ? { ok: false, error: "Discovery unavailable; enter a port manually." }
        : { ok: true, ports: [{ port: 3000, process: "node", address: "*:3000" }] };
      if (args[0] === "status") data.tunnels = backend.tunnels.map(t => ({ ...t }));
      if (args[0] === "start") {
        if (startError) data = { ok: false, error: startError };
        else {
          const tunnel = { id: "owned", machine: args[2], remote_port: Number(args[4]), local_port: Number(args[6]),
            origin: args[8], state: "forwarding", local_url: `http://127.0.0.1:${args[6]}` };
          backend.tunnels = [tunnel];
          data.tunnel = tunnel;
        }
      }
      if (args[0] === "stop") { backend.tunnels = backend.tunnels.filter(t => t.id !== args[2]); data.stopped = true; }
      return { code: data.ok ? 0 : 1, stdout: JSON.stringify(data) };
    },
  };
  vm.runInNewContext(source, scope, { filename: path.pathname });
  const mod = new scope.Forward();
  const cx = { focus_handle() {}, notify() {}, stop_propagation() {}, timer: { every: (_delay, callback) => timers.push(callback) },
    spawn: callback => tasks.push(callback(cx)) };
  mod.init({}, cx);
  let finished = 0;
  return { mod, cx, calls, backend, timers, closed, async settle() { while (finished < tasks.length) await tasks[finished++]; } };
}

test("user picks a discovered port, turns it on and off without closing the server", async () => {
  const p = await popup();
  await p.settle();
  p.mod.choose(0, p.cx);
  p.mod.port.handlers.submit({}, p.cx);
  await p.settle();

  assert.equal(p.mod.machine, "mac");
  assert.equal(p.mod.tunnels[0].local_port, 3000);
  assert.equal(p.mod.tunnels[0].origin, "user");
  p.mod.port.handlers.submit({}, p.cx);
  await p.settle();

  assert.deepEqual(p.calls.find(call => call[0] === "stop"), ["stop", "--id", "owned"]);
  assert.equal(p.mod.tunnels.length, 0);
});

test("agent-created tunnels appear on refresh and can be stopped by user", async () => {
  const p = await popup();
  await p.settle();
  p.backend.tunnels = [{ id: "agent-owned", machine: "mac", remote_port: 5173, local_port: 5174, origin: "agent", state: "forwarding" }];

  p.timers[0](p.cx);
  await p.settle();
  assert.equal(p.mod.tunnels[0].origin, "agent");
  p.mod.perform(["stop", "--id", "agent-owned"], p.cx);
  await p.settle();
  assert.equal(p.mod.tunnels.length, 0);
});

test("manual forwarding works when discovery fails and accepts a different local port", async () => {
  const p = await popup({ discoverError: true });
  await p.settle();
  assert.match(p.mod.error, /Discovery unavailable/);

  p.mod.port.set_value("3000");
  p.mod.local.set_value("3001");
  p.mod.toggle(p.cx);
  await p.settle();

  assert.equal(p.mod.tunnels[0].local_port, 3001);
  assert.equal(p.mod.error, "");
});

test("helper failure is shown without claiming that forwarding succeeded", async () => {
  const p = await popup({ startError: "Port occupied; choose another --local-port." });
  await p.settle();
  p.mod.choose(0, p.cx);
  p.mod.toggle(p.cx);
  await p.settle();

  assert.match(p.mod.error, /Port occupied/);
  assert.equal(p.mod.tunnels.length, 0);
  assert.equal(p.mod.busy, false);
});

test("Escape closes popup without stopping an agent's tunnel", async () => {
  const p = await popup();
  await p.settle();
  p.mod.render().handlers.on_key_down[0]({ key: "escape" }, p.cx);

  assert.deepEqual(p.closed, ["forward"]);
  assert.equal(p.calls.some(call => call[0] === "stop"), false);
});
