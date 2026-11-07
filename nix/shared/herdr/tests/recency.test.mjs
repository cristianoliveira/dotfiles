import assert from "node:assert/strict";
import test from "node:test";
import { observeRecentTabs } from "../mods/tmux-compat/history.js";
import { sortRecentGroups } from "../mods/tmux-picker/recency.js";

const space = (id, active, tab) => ({
  id, active, tabs: ["one", "two", "three"].map(id => ({ id, active: id === tab })),
});

test("recent focus keeps more than the last two tabs and ignores repeated observations", () => {
  let history = [];
  for (const tab of ["one", "two", "three", "one"]) {
    history = observeRecentTabs(history, [space("a", true, tab)]);
  }
  const expected = [
    { space: "a", tab: "one" }, { space: "a", tab: "three" }, { space: "a", tab: "two" },
  ];
  assert.deepEqual(history, expected);
  assert.deepEqual(observeRecentTabs(history, [space("a", true, "one")]), expected);
});

test("recent focus distinguishes spaces and prunes closed tabs/spaces", () => {
  const history = [
    { space: "remote/a", tab: "one" }, { space: "a", tab: "one" },
    { space: "gone", tab: "one" }, { space: "a", tab: "closed" },
  ];
  assert.deepEqual(observeRecentTabs(history, [space("a", true, "two"), space("remote/a", false, "one")]), [
    { space: "a", tab: "two" }, { space: "remote/a", tab: "one" }, { space: "a", tab: "one" },
  ]);
  assert.deepEqual(observeRecentTabs(history, []), []);
});

test("no active space preserves surviving history without treating inactive tab state as a visit", () => {
  const history = [{ space: "a", tab: "one" }];
  assert.deepEqual(observeRecentTabs(history, [space("a", false, "two")]), history);
});

const group = (id, tabs) => ({ w: { id }, ctxs: tabs.map(id => ({ ctx: { id } })) });

test("picker sorts spaces and their tabs by most recent focus without mutating source order", () => {
  const groups = [group("a", ["one", "two"]), group("b", ["one", "two"]), group("c", ["one"])];
  const before = structuredClone(groups);
  const sorted = sortRecentGroups(groups, [
    { space: "b", tab: "two" }, { space: "a", tab: "two" }, { space: "b", tab: "one" },
  ]);

  assert.deepEqual(sorted.map(g => g.w.id), ["b", "a", "c"]);
  assert.deepEqual(sorted[0].ctxs.map(c => c.ctx.id), ["two", "one"]);
  assert.deepEqual(sorted[1].ctxs.map(c => c.ctx.id), ["two", "one"]);
  assert.deepEqual(groups, before);
});

test("empty groups and stale visits cannot outrank a live recent tab", () => {
  const groups = [group("empty", []), group("a", ["one"])];
  const sorted = sortRecentGroups(groups, [{ space: "gone", tab: "closed" }, { space: "a", tab: "one" }]);
  assert.deepEqual(sorted.map(g => g.w.id), ["a", "empty"]);
});

test("unvisited spaces and tabs retain source order", () => {
  const groups = [group("b", ["two", "one"]), group("a", ["one"])];
  assert.deepEqual(sortRecentGroups(groups, []), groups);
});
