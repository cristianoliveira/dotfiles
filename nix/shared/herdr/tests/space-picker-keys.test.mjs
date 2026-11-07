import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";
import { sortRecentGroups } from "../mods/tmux-picker/recency.js";

function element() {
  const node = { handlers: {} };
  const builder = new Proxy(node, {
    get(target, name) {
      if (name in target) return target[name];
      if (name === "when") return (condition, apply) => condition ? apply(builder) : builder;
      return (...args) => { target.handlers[name] = args; return builder; };
    },
  });
  return builder;
}

async function picker(spaceList = [], visits = []) {
  const path = new URL("../mods/tmux-picker/main.js", import.meta.url);
  const source = (await readFile(path, "utf8"))
    .replace(/^import .*;$/gm, "")
    .replace("export default class Picker", "globalThis.Picker = class Picker");
  const calls = [];
  const scope = {
    View: class {}, div: element, svg: element, v_flex: element, h_flex: element,
    Input: { new: element }, theme: () => ({}), sortRecentGroups,
    agents: () => [], terminals: () => [], spaces: () => spaceList, shared: () => visits,
    closeOverlay: id => calls.push(["close", id]), props: () => ({ overlay: "picker" }),
    run: (...args) => calls.push(args),
  };
  vm.runInNewContext(source, scope, { filename: path.pathname });
  const mod = new scope.Picker();
  const rows = [
    { kind: "ctx", w: { active: true }, ctx: { id: "tab", active: true, name: "1" }, mine: [] },
    { kind: "new" }, { kind: "space", machine: null },
  ];
  Object.assign(mod, { at: 0, scroll: 0, filter: "", machines: [], rows: () => rows });
  let stopped = 0;
  return {
    mod, calls,
    press(keystroke, key = keystroke) {
      mod.render().handlers.on_key_down[0]({ keystroke, key, modifiers: { control: keystroke.startsWith("ctrl-") } }, {
        stop_propagation: () => stopped++, notify() {},
      });
    },
    stopped: () => stopped,
  };
}

test("space/tab picker keeps quiet spaces visible in recent order, including filtered results", async () => {
  const spaceList = [
    { id: "a", name: "Alpha", status: "blocked", tabs: [{ id: "one", name: "first" }] },
    { id: "b", name: "Beta", status: null, tabs: [{ id: "two", name: "second" }, { id: "three", name: "third" }] },
  ];
  const p = await picker(spaceList, [{ space: "b", tab: "three" }, { space: "a", tab: "one" }]);
  delete p.mod.rows;

  const rows = p.mod.rows();
  assert.deepEqual(Array.from(rows.filter(r => r.kind === "ctx"), r => r.ctx.id), ["three", "two", "one"]);
  assert.equal(rows.some(r => r.kind === "earlier"), false);
  assert.equal(rows.at(-2).kind, "new");
  assert.equal(rows.at(-1).kind, "space");

  p.mod.filter = "third";
  assert.deepEqual(Array.from(p.mod.rows().filter(r => r.kind === "ctx"), r => r.ctx.id), ["three"]);
});

test("space/tab picker Ctrl-j/k navigate and wrap across selectable items", async () => {
  const p = await picker();

  p.press("ctrl-j", "j");
  assert.equal(p.mod.at, 1);
  p.press("ctrl-k", "k");
  assert.equal(p.mod.at, 0);
  p.press("ctrl-k", "k");
  assert.equal(p.mod.at, 2);
  assert.equal(p.stopped(), 3);
});

test("space/tab picker keeps arrows, Escape and Ctrl-d", async () => {
  const p = await picker();
  p.press("down");
  assert.equal(p.mod.at, 1);
  p.press("up");
  assert.equal(p.mod.at, 0);

  p.press("ctrl-d", "d");
  assert.equal(p.calls[0][0], "close");
  assert.equal(p.calls[1][0], "tab.close");
  assert.equal(p.calls[1][1].id, "tab");
  p.press("escape");
  assert.equal(p.calls[2][0], "close");
});

test("space/tab picker leaves plain j/k and Ctrl-h/l to search input", async () => {
  const p = await picker();

  for (const key of ["j", "k", "ctrl-h", "ctrl-l"]) p.press(key);

  assert.equal(p.mod.at, 0);
  assert.equal(p.stopped(), 0);
  assert.deepEqual(p.calls, []);
});
