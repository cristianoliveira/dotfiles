import assert from "node:assert/strict";
import test from "node:test";
import { dismissEvents, observeEvents } from "../mods/intray/model.js";

const state = { version: 1, serial: 3, seen: [["one", "done"], ["two", "blocked"]],
  events: [{ id: 3, address: "new", status: "done" }, { id: 2, address: "two", status: "blocked" }, { id: 1, address: "one", status: "done" }] };

test("bulk dismissal removes only reviewed IDs, preserving new arrivals, serial and seen states", () => {
  const before = structuredClone(state);

  const result = dismissEvents(state, [1, 2]);

  assert.deepEqual(result.events.map(event => event.id), [3]);
  assert.equal(result.serial, 3);
  assert.deepEqual(result.seen, state.seen);
  assert.deepEqual(state, before);
  assert.equal(dismissEvents(state, []), state);
  assert.equal(dismissEvents(state, [99]), state);
});

test("dismiss all retains observation history so unchanged statuses do not recreate notifications", () => {
  const result = dismissEvents(state, state.events.map(event => event.id));

  const next = observeEvents(result, [
    { address: "one", status: "done", seq: 1 }, { address: "two", status: "blocked", seq: 2 },
  ]);

  assert.deepEqual(next.events, []);
  assert.equal(next.serial, state.serial);
});
