import assert from "node:assert/strict";
import test from "node:test";
import { broadcastPlan } from "../mods/tmux-compat/broadcast.js";

const focus = { space: "s", tab: "tab", pane: "p1", terminal: "t1", cwd: "/project" };
const spaces = [{ id: "s", machine: null }];
const panes = [{ pane: "p1", tab: "tab", terminal: "t1" }, { pane: "p2", tab: "tab", terminal: "t2" },
  { pane: "outside", tab: "another", terminal: "t3" }, { pane: "mod", tab: "tab", terminal: null }];
const terminals = ["t1", "t2", "t3"].map((address) => ({ address, state: "live" }));

test("broadcast pins only current-tab terminal panes and passes scope as literal argv", () => {
  const plan = broadcastPlan(focus, spaces, panes, terminals, "/home/agent's config");

  assert.equal(plan.script, "/home/agent's config/mods/tmux-compat/broadcast.py");
  assert.deepEqual(plan.command, ["python3", "-E", "-s", plan.script]);
  assert.deepEqual(JSON.parse(plan.args[plan.args.indexOf("--targets") + 1]), [
    { pane: "p1", terminal: "t1" }, { pane: "p2", terminal: "t2" },
  ]);
  assert.equal(plan.args[plan.args.indexOf("--tab") + 1], "tab");
  assert.equal(plan.args[plan.args.indexOf("--space") + 1], "s");
});

test("broadcast refuses unknown, replaced, remote, finished, or insufficient target context", () => {
  const plan = (f = focus, s = spaces, p = panes, t = terminals) => broadcastPlan(f, s, p, t, "/app");
  assert.throws(() => plan(null));
  assert.throws(() => plan({ ...focus, shown: "t9" }));
  assert.throws(() => plan(focus, [{ id: "s", machine: "server" }]));
  assert.throws(() => plan(focus, spaces, panes.slice(0, 1)));
  assert.throws(() => plan(focus, spaces, panes, [{ address: "t1", state: "live" }]));
});

test("duplicate references never result in duplicate delivery targets", () => {
  const plan = broadcastPlan(focus, spaces, [...panes, { ...panes[1], pane: "duplicate" }], terminals, "/app");

  assert.equal(JSON.parse(plan.args[1]).length, 2);
});
