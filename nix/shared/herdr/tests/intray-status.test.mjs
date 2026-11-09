import assert from "node:assert/strict";
import test from "node:test";
import { filterEvents } from "../mods/intray/model.js";

const events = [
  { id: 3, title: "Review", status: "blocked", space: "Wire", tab: "backend", address: "t3" },
  { id: 2, title: "Review", status: "done", space: "Wire", tab: "frontend", address: "t2" },
  { id: 1, title: "Deploy", status: "done", space: "Personal", tab: "docs", address: "t1" },
];

test("status filters intersect with search and preserve newest-first order", () => {
  assert.deepEqual(filterEvents(events, "", "done").map(event => event.id), [2, 1]);
  assert.deepEqual(filterEvents(events, "review", "done").map(event => event.id), [2]);
  assert.deepEqual(filterEvents(events, "wire", "blocked").map(event => event.id), [3]);
  assert.deepEqual(filterEvents(events, "deploy", "blocked"), []);
  assert.deepEqual(filterEvents(events, "", "all"), events);
  assert.deepEqual(filterEvents(events, "", "error"), []);
});

test("status filtering does not change stored events or fabricate errors from titles", () => {
  const source = [{ ...events[0], title: "Investigate error" }];
  const before = structuredClone(source);

  assert.deepEqual(filterEvents(source, "error", "blocked"), source);
  assert.deepEqual(filterEvents(source, "", "error"), []);
  assert.deepEqual(source, before);
});
