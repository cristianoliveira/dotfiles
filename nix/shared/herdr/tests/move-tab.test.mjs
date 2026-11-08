import assert from "node:assert/strict";
import test from "node:test";
import { moveTab } from "../mods/tmux-compat/move-tab.js";

const space = (active, selected, ids = ["one", "two", "three"]) => ({
  active, tabs: ids.map(id => ({ id, active: id === selected })),
});

for (const [direction, index] of [[-1, 1], [1, 3]]) {
  test(`moves current tab ${direction === -1 ? "left" : "right"} using a one-based index`, () => {
    const calls = [];
    const snapshot = [space(false, "one"), space(true, "two")];

    moveTab(snapshot, direction, (...args) => calls.push(args));

    assert.deepEqual(calls, [["tab.move", { id: "two", index }]]);
    assert.deepEqual(snapshot, [space(false, "one"), space(true, "two")]);
  });
}

for (const [name, snapshot, direction] of [
  ["first tab moving left", [space(true, "one")], -1],
  ["last tab moving right", [space(true, "three")], 1],
  ["only tab", [space(true, "one", ["one"])], 1],
  ["no spaces", [], 1],
  ["no active space", [space(false, "two")], 1],
  ["no active tab", [space(true, null)], 1],
  ["empty space", [space(true, null, [])], -1],
]) {
  test(`does not reorder with ${name}`, () => {
    const calls = [];

    moveTab(snapshot, direction, (...args) => calls.push(args));

    assert.deepEqual(calls, []);
  });
}
