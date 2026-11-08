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

function nativePair(axis = "row", active = 0) {
  const f = fixture();
  const order = ["left", "right"];
  let actual = order[active];
  const snapshot = { space: "space", tab: "tab", pane: actual };
  f.deps.focused = () => snapshot;
  f.deps.panes = () => order.map(pane => ({ pane, tab: "tab", terminal: `terminal-${pane}` }));
  f.deps.run = (name, args) => {
    f.calls.push([name, args]);
    const index = order.indexOf(actual);
    const direction = axis === "row" ? (index === 0 ? "right" : "left") : (index === 0 ? "down" : "up");
    if (name === "pane.focus") actual = args.pane;
    if (name === "pane.swap" && args.direction === direction) order.reverse();
  };
  return { ...f, order, actualFocus: () => actual };
}

test("two terminal panes rotate natively in one synchronous turn from either slot and axis", async () => {
  for (const axis of ["row", "column"]) {
    for (const active of [0, 1]) {
      const f = nativePair(axis, active);

      const pending = rotateTabPanes(f.deps);

      assert.deepEqual(f.order, ["right", "left"]);
      assert.equal(f.actualFocus(), f.order[active]);
      assert.equal(f.calls.some(call => call[0] === "python3"), false);
      assert.equal(await pending, true);
    }
  }
});

test("native command errors do not retry through the Core helper", async () => {
  const f = nativePair();
  f.deps.run = (name, args) => { f.calls.push([name, args]); throw new Error("layout unavailable"); };

  await assert.rejects(rotateTabPanes(f.deps), /layout unavailable/);

  assert.equal(f.calls.length, 1);
  assert.equal(f.calls[0][0], "pane.swap");
});

test("zoomed, temporarily replaced or opted-out terminals retain the versioned helper path", async () => {
  for (const mode of ["zoomed", "shown", "disabled"]) {
    const f = nativePair();
    if (mode === "disabled") f.deps.nativeRotation = false;
    if (mode === "zoomed") f.deps.spaces = () => [{ id: "space", machine: null, tabs: [{ id: "tab", zoomed: true }] }];
    if (mode === "shown") f.deps.focused = () => ({ space: "space", tab: "tab", pane: "left", shown: "temporary-terminal" });

    await rotateTabPanes(f.deps);

    assert.equal(f.calls[0][0], "python3");
    assert.equal(f.calls.some(call => call[0] === "pane.swap"), false);
  }
});

test("three terminal panes request a read-only native plan when available", async () => {
  const f = fixture();
  f.deps.panes = () => ["left", "right", "third"].map(pane => ({ pane, tab: "tab", terminal: `terminal-${pane}` }));

  await rotateTabPanes(f.deps);

  assert.equal(f.calls[0][0], "python3");
  assert.deepEqual(JSON.parse(f.calls[0][1][2]).panes, ["left", "right", "third"]);
  assert.equal(JSON.parse(f.calls[0][1][2]).native, true);
  assert.equal(f.calls.some(call => call[0] === "pane.swap"), false);
});

test("a master-stack native plan rotates all slots and restores focus before yielding", async () => {
  const f = fixture();
  const order = ["left", "right", "third"];
  let active = "left";
  const frames = [];
  f.deps.panes = () => order.map(pane => ({ pane, tab: "tab", terminal: `t-${pane}` }));
  f.deps.exec = async () => ({ code: 0, stdout: JSON.stringify({ pane: "third", changed: true,
    swaps: [{ pane: "third", direction: "left" }, { pane: "right", direction: "left" }] }) });
  f.deps.run = (name, args) => {
    f.calls.push([name, args]);
    if (name === "pane.focus") active = args.pane;
    if (name === "pane.swap") {
      const index = order.indexOf(active);
      assert.equal(args.direction, "left");
      assert.notEqual(active, "left");
      const neighbor = order.indexOf("left"); // Native geometry is keyed by the original identity.
      [order[neighbor], order[index]] = [order[index], order[neighbor]];
    }
    queueMicrotask(() => frames.push({ order: [...order], active }));
  };

  assert.equal(await rotateTabPanes(f.deps), true);

  assert.deepEqual(order, ["third", "left", "right"]);
  assert.equal(active, "third");
  assert.equal(f.calls.length, 5);
  assert.ok(frames.length > 0);
  assert.ok(frames.every(frame => frame.order.join() === order.join() && frame.active === active));
});

test("native plans are discarded after navigation, changed order, zoom or terminal replacement", async () => {
  for (const mode of ["navigation", "order", "zoom", "shown"]) {
    const f = fixture();
    let order = ["left", "right", "third"];
    let zoomed = false;
    f.deps.spaces = () => [{ id: "space", tabs: [{ id: "tab", zoomed }] }];
    f.deps.panes = () => order.map(pane => ({ pane, tab: "tab", terminal: `t-${pane}` }));
    f.deps.exec = async () => {
      if (mode === "navigation") f.focus({ space: "space", tab: "other", pane: "elsewhere" });
      if (mode === "order") order.reverse();
      if (mode === "zoom") zoomed = true;
      if (mode === "shown") f.focus({ space: "space", tab: "tab", pane: "left", shown: "replacement" });
      return { code: 0, stdout: JSON.stringify({ pane: "third", changed: true,
        swaps: [{ pane: "right", direction: "left" }, { pane: "third", direction: "left" }] }) };
    };

    assert.equal(await rotateTabPanes(f.deps), false);
    assert.deepEqual(f.calls, []);
  }
});

test("native plans cannot focus a valid pane outside the original slot", async () => {
  const f = fixture();
  f.deps.panes = () => ["left", "right", "third"].map(pane => ({ pane, tab: "tab", terminal: `t-${pane}` }));
  f.deps.exec = async () => ({ code: 0, stdout: JSON.stringify({ pane: "right", changed: true,
    swaps: [{ pane: "third", direction: "left" }, { pane: "right", direction: "left" }] }) });

  await assert.rejects(rotateTabPanes(f.deps), /invalid native plan/);
  assert.deepEqual(f.calls, []);
});

test("malformed native plans never execute partial commands", async () => {
  for (const swaps of [[{ pane: "right", direction: "left" }, { pane: "elsewhere", direction: "left" }],
    [{ pane: "right", direction: "left" }, { pane: "third", direction: "shell" }], null, []]) {
    const f = fixture();
    f.deps.panes = () => ["left", "right", "third"].map(pane => ({ pane, tab: "tab", terminal: `t-${pane}` }));
    f.deps.exec = async () => ({ code: 0, stdout: JSON.stringify({ pane: "third", changed: true, swaps }) });

    await assert.rejects(rotateTabPanes(f.deps));
    assert.deepEqual(f.calls, []);
  }
});

test("a mod pane retains the versioned helper rather than using terminal fast path", async () => {
  const f = fixture();
  f.deps.panes = () => [{ pane: "left", tab: "tab", terminal: "ta" }, { pane: "right", tab: "tab", mod: "files", terminal: null }];

  await rotateTabPanes(f.deps);

  assert.equal(f.calls[0][0], "python3");
  assert.equal(f.calls.some(call => call[0] === "pane.swap"), false);
});

async function compat(rotateTabPanes, options = {}) {
  const source = (await readFile(new URL("../mods/tmux-compat/main.js", import.meta.url), "utf8"))
    .replace(/^import .*;$/gm, "")
    .replace("export default class TmuxCompat", "globalThis.TmuxCompat = class TmuxCompat");
  const notices = [];
  const tasks = [];
  const scope = { View: class {}, rotateTabPanes, props: () => options, focused() {}, spaces() {}, panes() {}, appHome() {}, exec() {}, run() {},
    notify: notice => notices.push(notice) };
  vm.runInNewContext(source, scope);
  const view = new scope.TmuxCompat();
  const cx = { notify() {}, spawn: task => tasks.push(task(cx)) };
  return { view, cx, tasks, notices };
}

test("compat passes the custom-layout native rotation opt-out to its adapter", async () => {
  for (const options of [{ native_rotation: false }, { native_pair_rotation: false }]) {
    let nativeRotation;
    const f = await compat(async deps => { nativeRotation = deps.nativeRotation; }, options);

    f.view.rotatePanes(f.cx);
    await Promise.all(f.tasks);

    assert.equal(nativeRotation, false);
  }
});

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
