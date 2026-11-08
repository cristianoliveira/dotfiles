import assert from "node:assert/strict";
import test from "node:test";
import { readFile } from "node:fs/promises";
import vm from "node:vm";
import { shrinkPaneHeight } from "../mods/tmux-compat/pane-size.js";

function fixture() {
  let focus = { space: "space", tab: "tab", pane: "bottom" };
  let zoomed = false;
  const calls = [], commands = [];
  const deps = {
    focused: () => focus,
    spaces: () => [{ id: "space", machine: null, tabs: [{ id: "tab", zoomed }] }],
    panes: () => ["top", "bottom"].map(pane => ({ pane, tab: "tab" })),
    appHome: () => "/home/path with spaces/.config/herdr-app",
    exec: async (...args) => { calls.push(args); return { code: 0, stdout: '{"pane":"bottom","changed":true}' }; },
    run: (...args) => commands.push(args),
  };
  return { deps, calls, commands, focus: value => { focus = value; }, zoom: value => { zoomed = value; } };
}

test("height strip scopes the versioned helper and never moves keyboard focus", async () => {
  const f = fixture();

  assert.equal(await shrinkPaneHeight(f.deps), true);

  assert.deepEqual(f.calls[0].slice(0, 1), ["python3"]);
  assert.deepEqual(f.calls[0][1].slice(0, 3), ["-I", "/home/path with spaces/.config/herdr-app/mods/tmux-compat/rotate.py", "--shrink-height"]);
  assert.deepEqual(JSON.parse(f.calls[0][1][3]), { space: "space", tab: "tab", pane: "bottom", panes: ["top", "bottom"], machine: null });
  assert.deepEqual(f.commands, []);
});

test("single pane and missing model context are noops", async () => {
  for (const mode of ["single", "layout-terminal", "missing-tab"]) {
    const f = fixture();
    if (mode === "single") f.deps.panes = () => [{ pane: "bottom", tab: "tab" }];
    if (mode === "layout-terminal") f.focus(null);
    if (mode === "missing-tab") f.deps.spaces = () => [];

    assert.equal(await shrinkPaneHeight(f.deps), false);
    assert.deepEqual(f.calls, []);
  }
});

test("successful shrink unzooms only when the original pane remains selected", async () => {
  for (const navigate of [false, true]) {
    const f = fixture();
    f.zoom(true);
    f.deps.exec = async () => {
      if (navigate) f.focus({ space: "space", tab: "other", pane: "elsewhere" });
      return { code: 0, stdout: '{"pane":"bottom","changed":true}' };
    };

    await shrinkPaneHeight(f.deps);

    assert.deepEqual(f.commands, navigate ? [] : [["pane.zoom", { pane: "bottom" }]]);
  }
});

test("an already-sized zoomed pane still reveals its strip without a second layout write", async () => {
  const f = fixture();
  f.zoom(true);
  f.deps.exec = async () => ({ code: 0, stdout: '{"pane":"bottom","changed":false}' });

  assert.equal(await shrinkPaneHeight(f.deps), true);
  assert.deepEqual(f.commands, [["pane.zoom", { pane: "bottom" }]]);
});

test("a new zoom request during sizing is not undone", async () => {
  const f = fixture();
  f.deps.exec = async () => { f.zoom(true); return { code: 0, stdout: '{"pane":"bottom","changed":true}' }; };

  await shrinkPaneHeight(f.deps);

  assert.deepEqual(f.commands, []);
});

test("helper failures and unexpected responses never unzoom or refocus", async () => {
  for (const result of [{ code: 1, stderr: "conflict" }, { code: 0, stdout: "invalid" },
    { code: 0, stdout: '{"pane":"top","changed":true}' }, { code: 0, stdout: '{"pane":"bottom","changed":"yes"}' }]) {
    const f = fixture();
    f.zoom(true);
    f.deps.exec = async () => result;

    await assert.rejects(shrinkPaneHeight(f.deps));
    assert.deepEqual(f.commands, []);
  }
});

test("remote pane IDs and machine are passed as literal data", async () => {
  const f = fixture();
  f.focus({ space: "maya/space", tab: "maya/tab", pane: "maya/bottom" });
  f.deps.spaces = () => [{ id: "maya/space", machine: "maya", tabs: [{ id: "maya/tab" }] }];
  f.deps.panes = () => ["top", "bottom"].map(pane => ({ pane: `maya/${pane}`, tab: "maya/tab" }));
  f.deps.exec = async (...args) => { f.calls.push(args); return { code: 0, stdout: '{"pane":"maya/bottom","changed":true}' }; };

  await shrinkPaneHeight(f.deps);

  assert.equal(JSON.parse(f.calls[0][1][3]).machine, "maya");
  assert.deepEqual(f.commands, []);
});

async function compat(f) {
  const source = (await readFile(new URL("../mods/tmux-compat/main.js", import.meta.url), "utf8"))
    .replace(/^import .*;$/gm, "").replace("export default class TmuxCompat", "globalThis.TmuxCompat = class TmuxCompat");
  const keys = JSON.parse(await readFile(new URL("../keys.json", import.meta.url), "utf8"));
  const command = keys.global["ctrl-a ctrl-y"];
  const pending = [command?.slice("tmux-compat.".length)];
  const tasks = [], notices = [];
  let rotations = 0, dispatched;
  const dispatchComplete = new Promise(resolve => { dispatched = resolve; });
  const scope = { View: class {}, ...f.deps, props: () => ({}), shrinkPaneHeight,
    rotateTabPanes: async () => { rotations++; }, notify: notice => notices.push(notice),
    nextCommand: async () => {
      if (pending.length) return pending.shift();
      dispatched();
      return new Promise(() => {});
    } };
  vm.runInNewContext(source, scope);
  const view = new scope.TmuxCompat();
  view.observe = () => ({});
  const cx = { notify() {}, spawn: task => tasks.push(task(cx)) };
  return { view, cx, tasks, notices, dispatchComplete, rotations: () => rotations };
}

test("configured Ctrl+A Ctrl+Y reaches the real height adapter through the compat command loop", async () => {
  const f = fixture();
  const c = await compat(f);

  c.view.init({}, c.cx);
  await c.dispatchComplete;
  await c.tasks[1];

  assert.equal(f.calls.length, 1);
  assert.equal(f.calls[0][1][2], "--shrink-height");
  assert.equal(c.view.resizing, false);
  assert.deepEqual(c.notices, []);
});

test("height changes and rotations do not overlap, and failure releases the height guard", async () => {
  const f = fixture();
  f.deps.exec = async () => { throw new Error("conflict"); };
  const c = await compat(f);
  c.view.rotating = true;
  c.view.shrinkPane(c.cx);
  assert.equal(c.tasks.length, 0);
  c.view.rotating = false;
  c.view.resizing = true;
  c.view.rotatePanes(c.cx);
  assert.equal(c.rotations(), 0);
  c.view.resizing = false;

  c.view.shrinkPane(c.cx);
  await c.tasks[0];

  assert.equal(c.view.resizing, false);
  assert.equal(c.notices[0].title, "Pane resize failed");
  assert.equal(c.notices[0].body, "conflict");
});
