import assert from "node:assert/strict";
import test from "node:test";
import { emptyState, restoreState, observeEvents, dismissEvent, jumpCommand } from "../mods/intray/model.js";

const agent = (address, status, seq = 1) => ({
  address, status, seq, title: `Task ${address}`, space_name: "Project", tab_name: "Work",
});

test("intray records attention events newest first, not working or idle updates", () => {
  const state = observeEvents(emptyState(), [agent("older", "done", 2), agent("newer", "blocked", 5), agent("busy", "working", 9)]);

  assert.deepEqual(state.events.map(event => event.address), ["newer", "older"]);
  assert.deepEqual(state.events.map(event => event.status), ["blocked", "done"]);
});

test("equal sequences sort deterministically and duplicate terminal reports use the newest", () => {
  const agents = [agent("b", "done", 2), agent("a", "blocked", 2), agent("busy", "done", 1), agent("busy", "working", 3)];

  const state = observeEvents(emptyState(), agents);

  assert.deepEqual(state.events.map(event => event.address), ["a", "b"]);
  assert.deepEqual(agents.map(agent => agent.address), ["b", "a", "busy", "busy"]);
});

test("core acknowledgements and unchanged reports do not duplicate or erase unread messages", () => {
  const first = observeEvents(emptyState(), [agent("one", "done")]);

  const same = observeEvents(first, [agent("one", "done", 4)]);
  const read = observeEvents(same, [agent("one", "idle", 5)]);

  assert.equal(same, first);
  assert.deepEqual(read.events, first.events);
});

test("another working-to-done transition keeps both events for the same terminal", () => {
  const first = observeEvents(emptyState(), [agent("one", "done")]);
  const working = observeEvents(first, [agent("one", "working", 2)]);

  const next = observeEvents(working, [agent("one", "done", 3)]);

  assert.equal(next.events.length, 2);
  assert.notEqual(next.events[0].id, next.events[1].id);
});

test("empty startup snapshots do not forget previously observed statuses", () => {
  const first = observeEvents(emptyState(), [agent("one", "done")]);

  const empty = observeEvents(first, []);
  const resumed = observeEvents(empty, [agent("one", "done")]);

  assert.equal(resumed.events.length, 1);
});

test("unread events and remembered terminals stay bounded", () => {
  const agents = Array.from({ length: 1100 }, (_, index) => agent(`t${index}`, "done", index));

  const state = observeEvents(emptyState(), agents);

  assert.equal(state.events.length, 100);
  assert.equal(state.seen.length, 1000);
  assert.equal(state.events[0].address, "t1099");
  assert.equal(observeEvents(state, agents), state);
  const expanded = [...agents, agent("latest", "done", 1200)];
  const next = observeEvents(state, expanded);
  assert.equal(observeEvents(next, expanded), next);
  assert.equal(next.events[0].address, "latest");
});

test("persisted unread queue survives reopening and malformed storage is harmless", () => {
  const state = observeEvents(emptyState(), [agent("one", "blocked")]);

  assert.deepEqual(restoreState(JSON.stringify(state)), state);
  for (const value of [null, "broken", "null", '{"events":{}}', '{"version":900}']) {
    assert.deepEqual(restoreState(value), emptyState());
  }
});

test("invalid reports are ignored and labels are bounded literal text", () => {
  const state = observeEvents(emptyState(), [
    null, agent("", "done"), agent("bad", "other"), agent("invalid", "done", NaN), agent("negative", "done", -1),
    { ...agent("safe", "done"), title: "$(touch /tmp/not-a-command)" + "a".repeat(500) },
  ]);

  assert.equal(state.events.length, 1);
  assert.equal(state.events[0].title.length, 240);
  assert.ok(state.events[0].title.startsWith("$(touch"));
});

test("reading one event preserves other unread messages and prevents unchanged reports returning", () => {
  const first = observeEvents(emptyState(), [agent("one", "done"), agent("two", "blocked", 2)]);

  const read = dismissEvent(first, first.events[0].id);
  const reopened = observeEvents(restoreState(JSON.stringify(read)), [agent("one", "done"), agent("two", "blocked", 2)]);

  assert.deepEqual(reopened.events.map(event => event.address), ["one"]);
  assert.equal(dismissEvent(reopened, -1), reopened);
});

test("duplicate persisted IDs and unsafe counters cannot create ambiguous list keys", () => {
  const first = observeEvents(emptyState(), [agent("one", "done")]);
  const duplicate = { ...first, events: [...first.events, ...first.events] };

  assert.equal(restoreState(JSON.stringify(duplicate)).events.length, 1);
  assert.deepEqual(restoreState(JSON.stringify({ ...first, serial: Number.MAX_SAFE_INTEGER })), emptyState());
});

test("jump targets exact live terminal including remote addresses, never an ended terminal", () => {
  const event = { address: "remote/t1" };

  assert.deepEqual(jumpCommand(event, [{ address: "remote/t1", state: "live" }]),
    ["agent.focus", { terminal: "remote/t1" }]);
  assert.equal(jumpCommand(event, [{ address: "remote/t1", state: "finished" }]), null);
  assert.equal(jumpCommand(null, []), null);
});
