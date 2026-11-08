import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";
import { filterProjects, projectCommand, projectKey } from "../mods/project-picker/model.js";

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

async function picker(count = 3) {
  const path = new URL("../mods/project-picker/main.js", import.meta.url);
  const source = (await readFile(path, "utf8"))
    .replace(/^import .*;$/gm, "")
    .replace("export default class ProjectPicker", "globalThis.Picker = class ProjectPicker");
  const lists = [];
  const calls = [];
  const scope = {
    View: class {}, div: element, v_flex: element, h_flex: element,
    theme: () => ({}), Input: { new: element }, filterProjects, projectCommand, projectKey,
    v_virtual_list: (...args) => {
      const list = element();
      lists.push({ args, list });
      return list;
    },
    spaces: () => [], run: (...args) => calls.push(args),
    props: () => ({ overlay: "projects" }), closeOverlay() {},
  };
  vm.runInNewContext(source, scope, { filename: path.pathname });
  const mod = new scope.Picker();
  const scrolled = [];
  Object.assign(mod, {
    projects: Array.from({ length: count }, (_, i) => ({ label: `work/${i}`, folder: `/work/${i}` })),
    query: "", at: 0, scroll: { scroll_to_item: index => scrolled.push(index) },
  });
  let stopped = 0;
  let notified = 0;
  return {
    mod, scrolled, lists, calls,
    press(keystroke, key = keystroke) {
      mod.render().handlers.on_key_down[0]({ keystroke, key }, {
        stop_propagation: () => stopped++, notify: () => notified++,
      });
    },
    counts: () => ({ stopped, notified }),
  };
}

test("Ctrl-j and Ctrl-k select next/previous projects and wrap around", async () => {
  const p = await picker();

  p.press("ctrl-j", "j");
  assert.equal(p.mod.at, 1);
  p.press("ctrl-k", "k");
  assert.equal(p.mod.at, 0);
  p.press("ctrl-k", "k");
  assert.equal(p.mod.at, 2);
  assert.deepEqual(p.scrolled, [1, 0, 2]);
  assert.deepEqual(p.counts(), { stopped: 3, notified: 3 });
});

test("arrow navigation still works and empty results stay at zero", async () => {
  const p = await picker();
  p.press("down");
  p.press("up");
  assert.deepEqual(p.scrolled, [1, 0]);

  const empty = await picker(0);
  empty.press("ctrl-j", "j");
  empty.press("ctrl-k", "k");
  assert.equal(empty.mod.at, 0);
});

test("clicking duplicate project labels opens the selected machine, not the first row", async () => {
  const p = await picker();
  p.mod.projects = [
    { label: "work/dotfiles", folder: "/work/dotfiles", machine: "" },
    { label: "work/dotfiles", folder: "/work/dotfiles", machine: "mac" },
  ];

  p.mod.render();
  const { args, list } = p.lists[0];
  const key = args[3](1);
  assert.notEqual(key, args[3](0));
  list.handlers.on_item_click[0](key);

  assert.equal(p.calls[0][0], "space.new");
  assert.equal(p.calls[0][1].machine, "mac");
  assert.equal(p.calls[0][1].folder, "/work/dotfiles");
});

test("plain j/k and Ctrl-h/l remain available to search input", async () => {
  const p = await picker();

  for (const key of ["j", "k", "ctrl-h", "ctrl-l"]) p.press(key);

  assert.equal(p.mod.at, 0);
  assert.deepEqual(p.scrolled, []);
  assert.deepEqual(p.counts(), { stopped: 0, notified: 0 });
});
