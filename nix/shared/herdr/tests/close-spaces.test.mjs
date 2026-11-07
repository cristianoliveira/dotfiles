import assert from "node:assert/strict";
import test from "node:test";
import { SpaceCloser, filterSpaces } from "../mods/tmux-compat/close-spaces.js";

const space = (id, machine = null) => ({
  id, name: "project", folder: "/work/project", machine,
  tabs: [{ id: `${id}/tab`, panes: 1 }],
});
const live = [space("local"), space("server/remote", "server")];

test("starts with nothing selected and cannot close without review", () => {
  const closer = new SpaceCloser();

  assert.equal(closer.selected.size, 0);
  assert.equal(closer.beginReview(live), false);
  assert.deepEqual(closer.confirm(live).commands, []);
});

test("only existing space ids can be selected and toggled", () => {
  const closer = new SpaceCloser();
  closer.toggle("missing", live);
  closer.toggle("local", live);
  closer.toggle("local", live);

  assert.equal(closer.selected.size, 0);
});

test("review records machine and tab details but issues no commands", () => {
  const closer = new SpaceCloser();
  closer.toggle("server/remote", live);

  assert.equal(closer.beginReview(live), true);
  assert.equal(closer.review[0].machine, "server");
  assert.equal(closer.review[0].tabs.length, 1);
  assert.equal(closer.submitted, false);
});

test("explicit confirmation closes only reviewed ids, never names or new spaces", () => {
  const closer = new SpaceCloser();
  closer.toggle("local", live);
  closer.toggle("server/remote", live);
  closer.beginReview(live);

  const result = closer.confirm([...live, space("new")]);

  assert.deepEqual(result.commands, [
    ["space.close", { id: "local", confirmed: true }],
    ["space.close", { id: "server/remote", confirmed: true }],
  ]);
  assert.equal(result.status, "ready");
  assert.deepEqual(closer.confirm(live).commands, []);
});

test("selection cannot change after review and duplicate confirmation is inert", () => {
  const closer = new SpaceCloser();
  closer.toggle("local", live);
  closer.beginReview(live);
  closer.toggle("server/remote", live);

  assert.equal(closer.selected.size, 1);
  closer.confirm(live);
  assert.equal(closer.beginReview(live), false);
});

test("closed, renamed, or changed-tab spaces invalidate the entire confirmation", () => {
  for (const changed of [
    [live[1]],
    [{ ...live[0], name: "renamed" }, live[1]],
    [{ ...live[0], machine: "different-server" }, live[1]],
    [{ ...live[0], tabs: [...live[0].tabs, { id: "new-tab", panes: 1 }] }, live[1]],
    [{ ...live[0], tabs: [{ id: "local/tab", panes: 2 }] }, live[1]],
  ]) {
    const closer = new SpaceCloser();
    closer.toggle("local", live);
    closer.toggle("server/remote", live);
    closer.beginReview(live);

    const result = closer.confirm(changed);

    assert.equal(result.status, "changed");
    assert.deepEqual(result.commands, []);
    assert.equal(closer.review, null);
  }
});

test("spaces that disappear before review are removed from selection", () => {
  const closer = new SpaceCloser();
  closer.toggle("local", live);

  assert.equal(closer.beginReview([live[1]]), false);
  assert.equal(closer.selected.size, 0);
  assert.deepEqual(closer.confirm(live).commands, []);
});

test("back and cancellation never authorize closure", () => {
  const closer = new SpaceCloser();
  closer.toggle("local", live);
  closer.beginReview(live);
  closer.back();
  assert.deepEqual(closer.confirm(live).commands, []);

  closer.beginReview(live);
  closer.cancel();
  assert.deepEqual(closer.confirm(live).commands, []);
  assert.equal(closer.selected.size, 0);
});

test("filtering distinguishes machines and does not clear hidden selections", () => {
  const closer = new SpaceCloser();
  closer.toggle("local", live);

  assert.deepEqual(filterSpaces(live, "SERVER project"), [live[1]]);
  assert.deepEqual(filterSpaces(live, "missing"), []);
  assert.deepEqual(filterSpaces(live, ""), live);
  assert.equal(closer.selected.has("local"), true);
});
