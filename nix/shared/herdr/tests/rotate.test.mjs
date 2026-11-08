import assert from "node:assert/strict";
import test from "node:test";
import { readFile } from "node:fs/promises";
import vm from "node:vm";
import { rotateTabPanes } from "../mods/tmux-compat/rotate.js";

function fixture() {
  let focus = { space: "space", tab: "tab", pane: "left" };
  const calls = [];
  const deps = {
    focused: () => focus,
    spaces: () => [{ id: "space", machine: null, tabs: [{ id: "tab" }] }],
    panes: () => [{ pane: "left", tab: "tab" }, { pane: "right", tab: "tab" }, { pane: "elsewhere", tab: "other" }],
    appHome: () => "/home/person with spaces/.config/herdr-app",
    exec: async (...args) => { calls.push(args); return { code: 0, stdout: '{"pane":"right","changed":true}', stderr: "" }; },
    run: (...args) => calls.push(args),
  };
  return { deps, calls, focus: value => { focus = value; } };
}

test("rotation scopes the versioned helper to current tab and focuses the incoming pane", async () => {
  const f = fixture();

  assert.equal(await rotateTabPanes(f.deps), true);

  assert.equal(f.calls[0][0], "python3");
  assert.equal(f.calls[0][1][0], "-I");
  assert.equal(f.calls[0][1][1], "/home/person with spaces/.config/herdr-app/mods/tmux-compat/rotate.py");
  assert.deepEqual(JSON.parse(f.calls[0][1][2]), { space: "space", tab: "tab", pane: "left", panes: ["left", "right"], machine: null });
  assert.deepEqual(f.calls[1], ["pane.focus", { pane: "right" }]);
});

test("single pane, missing model pane or missing tab do not launch a helper", async () => {
  for (const mode of ["single", "layout-terminal", "missing-tab"]) {
    const f = fixture();
    if (mode === "single") f.deps.panes = () => [{ pane: "left", tab: "tab" }];
    if (mode === "layout-terminal") f.focus({ space: "space", tab: "tab", pane: null });
    if (mode === "missing-tab") f.deps.spaces = () => [];

    assert.equal(await rotateTabPanes(f.deps), false);
    assert.deepEqual(f.calls, []);
  }
});

test("another tab or pane selected during the operation is not refocused", async () => {
  for (const current of [{ space: "space", tab: "other", pane: "another" }, { space: "space", tab: "tab", pane: "right" }, null]) {
    const f = fixture();
    f.deps.exec = async () => {
      f.focus(current);
      return { code: 0, stdout: '{"pane":"right","changed":true}' };
    };

    assert.equal(await rotateTabPanes(f.deps), true);
    assert.deepEqual(f.calls, []);
  }
});

test("remote machine and qualified IDs are passed as literal data", async () => {
  const f = fixture();
  f.focus({ space: "maya/space", tab: "maya/tab", pane: "maya/left" });
  f.deps.spaces = () => [{ id: "maya/space", machine: "maya", tabs: [{ id: "maya/tab" }] }];
  f.deps.panes = () => [{ pane: "maya/left", tab: "maya/tab" }, { pane: "maya/right", tab: "maya/tab" }];
  f.deps.exec = async (...args) => {
    f.calls.push(args);
    return { code: 0, stdout: '{"pane":"maya/right","changed":true}' };
  };

  await rotateTabPanes(f.deps);

  assert.equal(JSON.parse(f.calls[0][1][2]).machine, "maya");
  assert.deepEqual(f.calls[1], ["pane.focus", { pane: "maya/right" }]);
});

async function compat(rotateTabPanes) {
  const source = (await readFile(new URL("../mods/tmux-compat/main.js", import.meta.url), "utf8"))
    .replace(/^import .*;$/gm, "")
    .replace("export default class TmuxCompat", "globalThis.TmuxCompat = class TmuxCompat");
  const notices = [];
  const tasks = [];
  const scope = { View: class {}, rotateTabPanes, focused() {}, spaces() {}, panes() {}, appHome() {}, exec() {}, run() {},
    notify: notice => notices.push(notice) };
  vm.runInNewContext(source, scope);
  const view = new scope.TmuxCompat();
  const cx = { notify() {}, spawn: task => tasks.push(task(cx)) };
  return { view, cx, tasks, notices };
}

test("compat ignores overlapping rotations until the current helper finishes", async () => {
  let finish;
  let calls = 0;
  const helper = new Promise(resolve => { finish = resolve; });
  const f = await compat(() => { calls++; return helper; });

  f.view.rotatePanes(f.cx);
  f.view.rotatePanes(f.cx);
  assert.equal(calls, 1);
  finish();
  await Promise.all(f.tasks);

  assert.equal(f.view.rotating, false);
});

test("compat reports helper failure and permits the next rotation", async () => {
  let calls = 0;
  const f = await compat(async () => { if (++calls === 1) throw new Error("conflict"); });

  f.view.rotatePanes(f.cx);
  await Promise.all(f.tasks);
  f.view.rotatePanes(f.cx);
  await Promise.all(f.tasks);

  assert.equal(calls, 2);
  assert.equal(f.view.rotating, false);
  assert.equal(f.notices[0].title, "Pane rotation failed");
  assert.equal(f.notices[0].body, "conflict");
});

test("conflict, helper failure or invalid target never issue a focus command", async () => {
  for (const result of [
    { code: 1, stderr: "Layout changed during rotation" },
    { code: 0, stdout: "invalid" },
    { code: 0, stdout: '{"pane":"elsewhere","changed":true}' },
  ]) {
    const f = fixture();
    f.deps.exec = async () => result;

    await assert.rejects(rotateTabPanes(f.deps));
    assert.deepEqual(f.calls, []);
  }
});
