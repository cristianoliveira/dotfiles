import assert from "node:assert/strict";
import test from "node:test";
import { observeSpaces, lastSpace } from "../mods/tmux-compat/history.js";

const spaces = (active, ids = ["a", "b", "c"]) => ids.map((id) => ({ id, active: id === active }));

test("first space has no previous space", () => {
  const history = observeSpaces([], spaces("a"));

  assert.deepEqual(history, ["a"]);
  assert.equal(lastSpace(history), null);
});

test("sidebar and picker changes both update the last visited space", () => {
  let history = observeSpaces([], spaces("a"));
  history = observeSpaces(history, spaces("b"));
  history = observeSpaces(history, spaces("c"));

  assert.deepEqual(history, ["c", "b"]);
  assert.equal(lastSpace(history), "b");
});

test("switching to the previous space toggles back on the next invocation", () => {
  let history = observeSpaces(["b", "a"], spaces("a"));
  assert.equal(lastSpace(history), "b");

  history = observeSpaces(history, spaces("b"));

  assert.equal(lastSpace(history), "a");
});

test("repeated renders and tab changes do not replace previous space", () => {
  assert.deepEqual(observeSpaces(["b", "a"], spaces("b")), ["b", "a"]);
});

test("closed spaces are removed instead of reopening or selecting them", () => {
  const history = observeSpaces(["b", "a"], spaces("b", ["b", "c"]));

  assert.deepEqual(history, ["b"]);
  assert.equal(lastSpace(history), null);
});

test("empty world drops stale history", () => {
  assert.deepEqual(observeSpaces(["a", "b"], []), []);
});

test("remote space ids remain distinct from local ones", () => {
  const current = [{ id: "server/a", active: true }, { id: "a", active: false }];

  assert.deepEqual(observeSpaces(["a"], current), ["server/a", "a"]);
});
