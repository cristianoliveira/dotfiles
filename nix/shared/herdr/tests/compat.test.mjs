import assert from "node:assert/strict";
import test from "node:test";
import { observeSpaces, lastSpace, observeTabs, lastTab } from "../mods/tmux-compat/history.js";

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

const withTabs = (id, active, tab, ids = ["one", "two", "three"]) => ({
  id, active, tabs: ids.map((id) => ({ id, active: id === tab })),
});

test("first tab has no previous tab", () => {
  const history = observeTabs({}, [withTabs("a", true, "one")]);

  assert.deepEqual(history, { a: ["one"] });
  assert.equal(lastTab(history, "a"), null);
  assert.equal(lastTab(history, "unknown"), null);
});

test("last-tab toggles between the last two visited tabs", () => {
  let history = observeTabs({}, [withTabs("a", true, "one")]);
  history = observeTabs(history, [withTabs("a", true, "two")]);
  assert.equal(lastTab(history, "a"), "one");

  history = observeTabs(history, [withTabs("a", true, "one")]);

  assert.equal(lastTab(history, "a"), "two");
});

test("each space keeps independent tab history", () => {
  const previous = { a: ["two", "one"], b: ["three", "one"] };

  const history = observeTabs(previous, [
    withTabs("a", false, "two"), withTabs("b", true, "two"),
  ]);

  assert.deepEqual(history, { a: ["two", "one"], b: ["two", "three"] });
  assert.equal(lastTab(history, "a"), "one");
  assert.equal(lastTab(history, "b"), "three");
});

test("inactive spaces do not record unseen tab selections", () => {
  const history = observeTabs({ a: ["two", "one"] }, [
    withTabs("a", false, "three"), withTabs("b", false, "one"),
  ]);

  assert.deepEqual(history, { a: ["two", "one"] });
});

test("closed tabs are pruned even in inactive spaces", () => {
  const history = observeTabs({ a: ["two", "one"], b: ["one"] }, [
    withTabs("a", false, "two", ["two"]),
  ]);

  assert.deepEqual(history, { a: ["two"] });
  assert.equal(lastTab(history, "a"), null);
});

test("closed spaces and empty tab lists drop their histories", () => {
  assert.deepEqual(observeTabs({ a: ["one"] }, []), {});
  assert.deepEqual(observeTabs({ a: ["one"] }, [withTabs("a", true, null, [])]), {});
});

test("repeated renders preserve both histories without mutating input", () => {
  const previous = { a: ["two", "one"] };

  assert.deepEqual(observeTabs(previous, [withTabs("a", true, "two")]), previous);
  assert.deepEqual(previous, { a: ["two", "one"] });
});
