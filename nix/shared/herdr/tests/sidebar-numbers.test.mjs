import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";

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

async function loadMod(name, run) {
  const path = new URL(`../mods/${name}/main.js`, import.meta.url);
  const source = (await readFile(path, "utf8"))
    .replace(/^import .*;$/gm, "")
    .replace(/export default class /, "globalThis.Mod = class ")
    .replace(/export function /g, "function ");
  const scope = { View: class {}, div: element, svg: element, h_flex: element, run };
  vm.runInNewContext(source, scope, { filename: path.pathname });
  return new scope.Mod();
}

const theme = {
  working: "#b58900", blocked: "#dc322f", done: "#859900",
  idle: "#657b83", muted: "#839496", foreground: "#eee8d5", raised: "#073642",
};

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
