import assert from "node:assert/strict";
import test from "node:test";
import { filterEvents } from "../mods/intray/model.js";

const events = [
  { id: 3, title: "Review authentication", space: "Wire", tab: "backend", address: "maya/t3", status: "blocked" },
  { id: 2, title: "Deploy docs [v2]", space: "Personal", tab: "website", address: "t2", status: "done" },
  { id: 1, title: "Fix authentication", space: "Wire", tab: "frontend", address: "t1", status: "done" },
];

test("notification search matches literal text across title, space, tab, terminal and status", () => {
  const cases = [
    ["AUTHENTICATION", [3, 1]], ["wire backend", [3]], [" Maya/T3 ", [3]],
    ["needs input", [3]], ["blocked", [3]], ["finished wire", [1]], ["done", [2, 1]],
    ["[v2]", [2]], [".*", []], ["absent", []], ["wire website", []],
  ];
  for (const [query, ids] of cases) {
    assert.deepEqual(filterEvents(events, query).map(event => event.id), ids, query);
  }
});

test("search preserves newest-first order and does not mutate notifications", () => {
  const before = structuredClone(events);

  assert.deepEqual(filterEvents(events, " \n\t"), events);
  assert.deepEqual(filterEvents(events, "authentication").map(event => event.id), [3, 1]);
  assert.deepEqual(filterEvents([], "anything"), []);
  assert.deepEqual(events, before);
});
