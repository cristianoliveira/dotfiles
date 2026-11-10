import assert from "node:assert/strict";
import test from "node:test";
import { startArgs, matchingTunnel } from "../mods/port-forward/model.js";

test("manual forwarding defaults local port to remote and marks user origin", () => {
  assert.deepEqual(startArgs("mac", "3000", ""), ["start", "--machine", "mac", "--port", "3000", "--local-port", "3000", "--origin", "user"]);
  assert.equal(startArgs("mac", "3000", "3001")[6], "3001");
});

test("invalid or absent ports and machine are rejected before invoking helper", () => {
  for (const value of ["", "0", "65536", "3000;rm", "3.5"]) assert.throws(() => startArgs("mac", value, ""));
  assert.throws(() => startArgs("", "3000", ""));
});

test("toggle matches machine and both ports, including agent-created tunnels", () => {
  const tunnel = { id: "a", machine: "mac", remote_port: 3000, local_port: 3001, state: "forwarding", origin: "agent" };
  assert.equal(matchingTunnel([tunnel], "mac", "3000", "3001"), tunnel);
  assert.equal(matchingTunnel([tunnel], "mac", "3000", ""), null);
  assert.equal(matchingTunnel([tunnel], "maya", "3000", "3001"), null);
  assert.equal(matchingTunnel([tunnel], "mac", "invalid", ""), null);
});
