import assert from "node:assert/strict";
import test from "node:test";
import { observeRecentTabs } from "../mods/tmux-compat/history.js";

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
