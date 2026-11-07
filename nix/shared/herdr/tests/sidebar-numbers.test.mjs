import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";
import { formatStatusTime } from "../mods/tmux-status/clock.js";

function element() {
  const node = { children: [], attributes: {} };
  const builder = new Proxy(node, {
    get(target, name) {
      if (name === "child") return child => { target.children.push(child); return builder; };
      if (name === "when") return (condition, apply) => condition ? apply(builder) : builder;
      if (name in target) return target[name];
      return (...args) => { target.attributes[name] = args; return builder; };
    },
  });
  return builder;
}

async function loadMod(name, run, overrides = {}) {
  const path = new URL(`../mods/${name}/main.js`, import.meta.url);
  const source = (await readFile(path, "utf8"))
    .replace(/^import .*;$/gm, "")
    .replace(/export default class /, "globalThis.Mod = class ")
    .replace(/export function /g, "function ");
  const scope = { View: class {}, div: element, svg: element, h_flex: element, run, formatStatusTime, ...overrides };
  vm.runInNewContext(source, scope, { filename: path.pathname });
  return new scope.Mod();
}

const theme = {
  working: "#b58900", blocked: "#dc322f", done: "#859900",
  idle: "#657b83", muted: "#839496", foreground: "#eee8d5", raised: "#073642",
};

test("bottom status shows computer and agents without a shared branch", async () => {
  const mod = await loadMod("tmux-status", () => {}, {
    theme: () => theme,
    spaces: () => [{ active: true, machine: "workstation", branch: "main" }],
    agents: () => [{ status: "working" }, { status: "blocked" }],
  });

  const row = mod.render();

  assert.equal(row.children.length, 2);
  assert.equal(row.children[0].children.at(-1), "workstation");
  assert.equal(row.children[1].children[0], "2 agents");
  assert.equal(row.children[1].children[1].children[0], "· 1 needs you");

});

test("bottom status handles no active space, no branch, and no agents", async () => {
  const mod = await loadMod("tmux-status", () => {}, {
    theme: () => theme, spaces: () => [], agents: () => [],
  });

  const row = mod.render();

  assert.equal(row.children.length, 2);
  assert.equal(row.children[0].children.at(-1), "This computer");
  assert.equal(row.children[1].children[0], "0 agents");
  assert.equal(row.children[1].children.length, 1);
});

test("bottom clock refreshes at minute changes without redrawing for each tick", async () => {
  let now = new Date(2026, 10, 7, 19, 5, 58);
  let tick;
  let notifications = 0;
  const cx = {
    timer: { every: (_ms, callback) => { tick = callback; } },
    notify: () => { notifications++; },
  };
  const mod = await loadMod("tmux-status", () => {}, {
    props: () => ({ mode: "clock" }),
    Date: class { constructor() { return now; } },
    theme: () => theme, spaces: () => [], agents: () => [],
  });

  mod.init({}, cx);
  assert.equal(mod.render().children[0], "19:05 Sat 07-Nov-26");
  now = new Date(2026, 10, 7, 19, 5, 59);
  tick(cx);
  assert.equal(notifications, 0);

  now = new Date(2026, 10, 7, 19, 6, 0);
  tick(cx);
  assert.equal(notifications, 1);
  assert.equal(mod.render().children[0], "19:06 Sat 07-Nov-26");
});

test("pane footer uses its own folder and branch, not another pane's", async () => {
  const paneList = [
    { pane: "pane-a", cwd: "/home/me/repo-a", branch: "feature-a", title: "Pi" },
    { pane: "pane-b", cwd: "/home/me/repo-b", branch: "feature-b", title: "shell" },
  ];
  for (const pane of paneList) {
    const mod = await loadMod("pane-footer", () => {}, {
      theme: () => theme, panes: () => paneList,
      props: () => ({ pane: pane.pane }), home: () => "/home/me",
    });

    const row = mod.render();

    assert.equal(row.children[1].children[0], pane.cwd.replace("/home/me", "~"));
    assert.equal(row.children[2].children.at(-1), pane.branch);
    assert.equal(row.attributes.border_t[0], 1);
  }
});

test("pane footer omits branch outside Git and tolerates a closed pane", async () => {
  const paneList = [{ pane: "pane-a", cwd: "/tmp", title: "shell" }];
  let paneId = "pane-a";
  const mod = await loadMod("pane-footer", () => {}, {
    theme: () => theme, panes: () => paneList,
    props: () => ({ pane: paneId }), home: () => "/home/me",
  });

  assert.equal(mod.render().children.length, 2);
  paneId = "closed";
  assert.equal(mod.render().children.length, 0);
});

for (const name of ["number-spaces", "number-agents"]) {
  for (const status of ["working", "blocked", "done", "idle", "unknown"]) {
    test(`${name} uses a colored number instead of a status icon for ${status}`, async () => {
      const calls = [];
      const mod = await loadMod(name, (...args) => calls.push(args));
      const row = name === "number-spaces"
        ? mod.compact({ w: { id: "space-1", active: true, status }, i: 1 }, theme)
        : mod.compact({ address: "t1", pane: "pane-1", status }, 1, theme);

      assert.equal(row.children.length, 1);
      const label = row.children[0];
      assert.equal(label.children.at(-1).children[0], "2");
      assert.equal(label.attributes.text_color[0], theme[status] ?? theme.muted);
      if (status === "working") {
        assert.equal(label.children.length, 2);
        assert.equal(label.children[0].attributes.bg[0], theme.working + "30");
        assert.equal(label.children[0].attributes.loop[0], "opacity");
        assert.equal(label.children[0].attributes.loop[1].period, 1600);
        assert.equal(label.children.at(-1).attributes.loop, undefined);
      } else {
        assert.equal(label.children.length, 1);
      }
      if (name === "number-spaces") assert.equal(row.attributes.bg[0], theme.raised);

      row.attributes.on_click[0]();

      assert.equal(calls[0][0], name === "number-spaces" ? "space.select" : "pane.focus");
      assert.equal(Object.values(calls[0][1])[0], name === "number-spaces" ? "space-1" : "pane-1");
    });
  }
}
