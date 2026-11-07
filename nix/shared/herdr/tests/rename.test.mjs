import assert from "node:assert/strict";
import test from "node:test";
import { folderTabName } from "../mods/tmux-compat/rename.js";

const focused = (cwd) => ({ tab: "tab-a", pane: "pane-a", terminal: "t1", cwd });

test("renames the focused tab from its terminal's current folder", () => {
  assert.deepEqual(folderTabName(focused("/home/me/work/project")), { id: "tab-a", name: "project" });
});

test("ignores trailing separators and handles the filesystem root", () => {
  assert.deepEqual(folderTabName(focused("/home/me/project///")), { id: "tab-a", name: "project" });
  assert.deepEqual(folderTabName(focused("/")), { id: "tab-a", name: "/" });
});

test("keeps whitespace, Unicode, and shell punctuation literal", () => {
  assert.deepEqual(folderTabName(focused("/work/agent's $(touch NEVER); 日本語 ")), {
    id: "tab-a", name: "agent's $(touch NEVER); 日本語 ",
  });
});

test("uses explicit machine-qualified tab ids for remote terminals", () => {
  assert.deepEqual(folderTabName({ ...focused("/srv/project"), tab: "server/tab-a" }), {
    id: "server/tab-a", name: "project",
  });
});

test("does not rename from missing cwd or non-terminal focus", () => {
  assert.equal(folderTabName(null), null);
  assert.equal(folderTabName(focused(null)), null);
  assert.equal(folderTabName(focused("")), null);
  assert.equal(folderTabName({ ...focused("/project"), pane: null }), null);
  assert.equal(folderTabName({ ...focused("/project"), terminal: null }), null);
  assert.equal(folderTabName({ ...focused("/project"), tab: null }), null);
});
