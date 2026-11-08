import assert from "node:assert/strict";
import test from "node:test";
import { moveTabTo } from "../mods/tmux-compat/move-tab.js";

const snapshot = () => [{ id: "space", tabs: [{ id: "one" }, { id: "two" }, { id: "three" }] }];
const target = { spaceId: "space", tabId: "two" };

for (const [value, index] of [["0", 1], ["1", 2], ["2", 3]]) {
  test(`moves captured tab to zero-based position ${value}`, () => {
    const calls = [];

    const error = moveTabTo(snapshot(), target, value, (...args) => calls.push(args));

    assert.equal(error, null);
    assert.deepEqual(calls, [["tab.move", { id: "two", index }]]);
  });
}

for (const value of ["", " ", "-1", "1.5", "2x", "3", "999999999999999999999", "1; echo bad"]) {
  test(`rejects invalid position ${JSON.stringify(value)} without moving a tab`, () => {
    const calls = [];

    const error = moveTabTo(snapshot(), target, value, (...args) => calls.push(args));

    assert.equal(typeof error, "string");
    assert.deepEqual(calls, []);
  });
}

for (const world of [[], [{ id: "space", tabs: [{ id: "other", active: true }] }]]) {
  test("does not move a replacement tab when captured tab or space closed", () => {
    const calls = [];

    const error = moveTabTo(world, target, "0", (...args) => calls.push(args));

    assert.equal(error, "The original tab is no longer available. Cancel and try again.");
    assert.deepEqual(calls, []);
  });
}
