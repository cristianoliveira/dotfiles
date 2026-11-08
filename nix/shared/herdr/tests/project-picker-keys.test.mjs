import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";
import { filterProjects, projectCommand, projectKey } from "../mods/project-picker/model.js";
import { refreshProjects, restoreProjectCache } from "../mods/project-picker/discovery.js";

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

async function picker(count = 3, options = {}) {
  const path = new URL("../mods/project-picker/main.js", import.meta.url);
  const source = (await readFile(path, "utf8"))
    .replace(/^import .*;$/gm, "")
    .replace("export default class ProjectPicker", "globalThis.Picker = class ProjectPicker");
  const lists = [];
  const calls = [];
  let cache = options.cache;
  const scope = {
    refreshProjects: args => refreshProjects({ ...args, now: () => 100 }), restoreProjectCache,
    shared: () => cache, setShared: (_key, value) => { cache = value; },
    exec: async (command, args) => {
      if (args.includes("--list-machines")) return options.listing ?? { code: 0, stdout: '{"machines":["mac"]}' };
      return (options.exec ?? (() => assert.fail("unexpected scan")))(command, args);
    },
    appHome: () => "/app", home: () => "/home/me",
    InputState: { new: () => ({ on() {}, focus() {} }) },
    VirtualListScrollHandle: { new: () => ({ scroll_to_item() {} }) },
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
    mod, scrolled, lists, calls, cache: () => cache,
    init() {
      const tasks = [];
      const cx = { focus_handle() {}, notify() {}, spawn: task => tasks.push(task(cx)) };
      mod.init({}, cx);
      return Promise.all(tasks);
    },
    press(keystroke, key = keystroke) {
      mod.render().handlers.on_key_down[0]({ keystroke, key }, {
        stop_propagation: () => stopped++, notify: () => notified++,
      });
    },
    counts: () => ({ stopped, notified }),
  };
}

test("picker opens cached projects immediately and skips fresh scans", async () => {
  const p = await picker(0, { cache: { version: 1, entries: [
    { machine: "mac", updatedAt: 99, projects: [{ label: "work/cached", folder: "/work/cached" }], warnings: [] },
    { machine: "", updatedAt: 99, projects: [], warnings: [] },
  ] } });

  const done = p.init();
  assert.equal(p.mod.projects[0].label, "work/cached");
  await done;

  assert.equal(p.mod.projects[0].machine, "mac");
  assert.equal(p.mod.loading, false);
});

test("progressive loading keeps selected cached project when local results arrive", async () => {
  let resolveLocal;
  const local = new Promise(resolve => { resolveLocal = resolve; });
  const p = await picker(0, {
    cache: { version: 1, entries: [
      { machine: "mac", updatedAt: 99, projects: [{ label: "work/cached", folder: "/work/cached" }], warnings: [] },
    ] },
    exec: async (_command, args) => {
      assert.equal(args.includes("--all-machines"), false);
      return local;
    },
  });

  const done = p.init();
  assert.equal(p.mod.projects[p.mod.at].label, "work/cached");
  resolveLocal({ code: 0, stdout: '{"projects":[{"label":"work/local","folder":"/work/local"}],"warnings":[]}' });
  await done;

  assert.equal(p.mod.at, 1);
  assert.equal(p.mod.projects[p.mod.at].label, "work/cached");
  assert.equal(p.cache().entries.length, 2);
});

test("cold picker scans machines separately and stores each result", async () => {
  const scans = [];
  const p = await picker(0, { exec: async (_command, args) => {
    scans.push(Array.from(args));
    const machine = args.includes("--remote") ? args.at(-1) : "local";
    return { code: 0, stdout: JSON.stringify({ projects: [{ label: `work/${machine}`, folder: `/work/${machine}` }], warnings: [] }) };
  } });

  await p.init();

  assert.equal(scans.length, 2);
  assert.equal(scans[0].includes("--remote"), false);
  assert.equal(scans[1].at(-1), "mac");
  assert.deepEqual(Array.from(p.mod.projects, project => project.machine), ["", "mac"]);
  assert.equal(p.cache().entries.length, 2);
});

test("machine listing failure retains cached projects and reports a warning", async () => {
  const p = await picker(0, {
    listing: { code: 1, stdout: "" },
    cache: { version: 1, entries: [
      { machine: "mac", updatedAt: 99, projects: [{ label: "work/cached", folder: "/work/cached" }], warnings: [] },
      { machine: "", updatedAt: 99, projects: [], warnings: [] },
    ] },
  });

  await p.init();

  assert.equal(p.mod.projects[0].label, "work/cached");
  assert.match(p.mod.warning, /Cannot list machines/);
  assert.equal(p.mod.loading, false);
});

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
