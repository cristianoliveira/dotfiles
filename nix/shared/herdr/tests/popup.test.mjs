import assert from "node:assert/strict";
import test from "node:test";
import { popupPlan, openPopup, releasePopup, popupIsLive, POPUP_LABEL } from "../mods/tmux-compat/popup.js";

const focus = { space: "local", tab: "tab", pane: "pane", terminal: "t1", cwd: "/work/project" };
const spaces = [{ id: "local", machine: null }];
const response = (data, code = 0) => ({
  code, stdout: code === 0 ? JSON.stringify(data) : "", stderr: code === 0 ? "" : JSON.stringify(data),
});
const owned = { address: "t99", state: "live", labels: { [POPUP_LABEL]: "1" } };

function adapters(overrides = {}) {
  const calls = [];
  return {
    calls,
    check: async (script) => { calls.push(["check", script]); return true; },
    core: async (args) => {
      calls.push(args);
      return response(args[0] === "run" ? { address: "t99", state: "live" } : owned);
    },
    open: (address) => { calls.push(["open", address]); return "overlay-1"; },
    ...overrides,
  };
}

test("popup command uses the focused terminal's project folder as literal argv data", async () => {
  const plan = popupPlan({ ...focus, cwd: "/work/agent's $(touch NEVER); 日本語" }, spaces);
  const io = adapters();

  const result = await openPopup(plan, io);

  assert.deepEqual(result, { address: "t99", overlay: "overlay-1" });
  const command = io.calls.find((call) => call[0] === "run");
  assert.deepEqual(command.slice(-4), ["--", "env", "--", plan.script]);
  assert.equal(command[command.indexOf("--cwd") + 1], plan.cwd);
  assert.ok(command.includes("--no-parent"));
  assert.ok(command.includes("--no-notify"));
  assert.ok(command.includes("--rm"));
  assert.ok(!command.includes("--keep"));
});

test("root and trailing slashes produce the intended script path", () => {
  assert.equal(popupPlan({ ...focus, cwd: "/" }, spaces).script, "/.tmp/popup");
  assert.equal(popupPlan({ ...focus, cwd: "/project///" }, spaces).script, "/project/.tmp/popup");
});

test("missing focus, cwd or owning space refuses launch", () => {
  for (const current of [null, { ...focus, pane: null }, { ...focus, terminal: null },
    { ...focus, cwd: null }, { ...focus, cwd: "relative" }]) {
    assert.throws(() => popupPlan(current, spaces));
  }
  assert.throws(() => popupPlan(focus, []));
});

test("remote projects never fall back to executing a local script", () => {
  assert.throws(() => popupPlan(focus, [{ id: "local", machine: "server" }]), /local/i);
});

test("missing or non-executable scripts do not create terminals", async () => {
  const io = adapters({ check: async () => false });

  await assert.rejects(openPopup(popupPlan(focus, spaces), io), /chmod \+x \.tmp\/popup/);
  assert.deepEqual(io.calls, []);
});

test("failed core launch or malformed receipt does not open or kill arbitrary terminals", async () => {
  for (const result of [response({ error: { message: "launch failed" } }, 1),
    response({ address: "server/t99", state: "live" }),
    { code: 0, stdout: "invalid JSON", stderr: "" }]) {
    const io = adapters({ core: async () => result });

    await assert.rejects(openPopup(popupPlan(focus, spaces), io));
    assert.ok(!io.calls.some((call) => call[0] === "open"));
  }
});

test("overlay creation failure releases the terminal it created", async () => {
  const io = adapters({ open: () => { throw new Error("overlay failed"); } });

  await assert.rejects(openPopup(popupPlan(focus, spaces), io), /overlay failed/);
  assert.ok(io.calls.some((call) => call[0] === "kill" && call[1] === "t99"));
});

test("cleanup kills only live terminals with the ownership label", async () => {
  const calls = [];
  await releasePopup("t99", async (args) => {
    calls.push(args);
    return response(owned);
  });

  assert.deepEqual(calls, [["get", "--json", "t99"], ["kill", "t99"]]);
  for (const record of [{ ...owned, labels: {} }, { ...owned, keep: true }, { ...owned, state: "exited" }]) {
    const calls = [];
    await releasePopup("t99", async (args) => { calls.push(args); return response(record); });
    assert.equal(calls.length, 1);
  }
});

test("already-removed terminals are harmless, but unrelated cleanup failures surface", async () => {
  await releasePopup("t99", async () => response({ error: { kind: "not_found" } }, 3));
  await assert.rejects(releasePopup("server/t99", async () => response(owned)));
  await assert.rejects(releasePopup("t99", async () => response({ ...owned, address: "t88" })), /mismatched/);
  await assert.rejects(releasePopup("t99", async () => response({ error: { kind: "unavailable" } }, 1)));
});

test("finished startup does not create an empty overlay", async () => {
  const io = adapters({ core: async () => response({ address: "t99", state: "exited" }) });

  assert.equal(await openPopup(popupPlan(focus, spaces), io), null);
  assert.ok(!io.calls.some((call) => call[0] === "open"));
});

test("toggle inspection recognizes only a live popup still owned by compat", async () => {
  assert.equal(await popupIsLive("t99", async () => response(owned)), true);
  assert.equal(await popupIsLive("t99", async () => response({ ...owned, keep: true })), false);
  assert.equal(await popupIsLive("t99", async () => response({ error: { kind: "not_found" } }, 3)), false);
});

test("kill racing with auto-removal is accepted only after checking that terminal is gone", async () => {
  const calls = [];
  await releasePopup("t99", async (args) => {
    calls.push(args);
    if (calls.length === 1) return response(owned);
    return response({ error: { kind: "not_found" } }, 3);
  });

  assert.deepEqual(calls, [["get", "--json", "t99"], ["kill", "t99"], ["get", "--json", "t99"]]);
});
