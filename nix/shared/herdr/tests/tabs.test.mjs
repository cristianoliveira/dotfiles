import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";

function element() {
  const node = { nodes: [], attributes: {} };
  const builder = new Proxy(node, {
    get(target, name) {
      if (name === "child") return child => { target.nodes.push(child); return builder; };
      if (name === "children") return children => { target.nodes.push(...children); return builder; };
      if (name === "when") return (condition, apply) => condition ? apply(builder) : builder;
      if (name in target) return target[name];
      return (...args) => { target.attributes[name] = args; return builder; };
    },
  });
  return builder;
}

function find(node, id) {
  if (node?.attributes?.id?.[0] === id) return node;
  for (const child of node?.nodes ?? []) {
    const result = find(child, id);
    if (result) return result;
  }
}

async function tabs(platform, mode) {
  const calls = [];
  const path = new URL("../mods/tmux-tabs/main.js", import.meta.url);
  const source = (await readFile(path, "utf8"))
    .replace(/^import .*;$/gm, "")
    .replace("export default class Tabs", "globalThis.Tabs = class Tabs");
  const scope = {
    View: class {}, div: element, svg: element, image: element, h_flex: element,
    theme: () => ({}), panes: () => [], layout: () => null, settings: () => ({ zoom: 1 }),
    window: () => ({ platform, buttons: true, titlebar: "none" }),
    shared: () => ["files", "changes"], openOverlay: () => {}, props: () => ({ mode }),
    spaces: () => [{ id: "space", active: true, tabs: [{ id: "tab", name: "1", active: true }] }],
    run: (...args) => calls.push(args), localStorage: { getItem: () => null },
  };
  vm.runInNewContext(source, scope, { filename: path.pathname });
  const mod = new scope.Tabs();
  mod.init();
  return { row: mod.render(), calls };
}

for (const platform of ["linux", "macos", "windows"]) {
  test(`bottom tabs omit window controls on ${platform} but retain tab and panel controls`, async () => {
    const { row } = await tabs(platform);

    for (const id of ["minimize", "maximize", "close-window"]) assert.equal(find(row, id), undefined);
    for (const id of ["tab-tab", "close-tab", "tab-new", "panel-files", "panel-changes"]) {
      assert.ok(find(row, id), `${id} remains available`);
    }
  });
}

test("tab-only strip keeps tabs without right-side controls", async () => {
  const { row } = await tabs("linux", "tabs");

  assert.ok(find(row, "tab-tab"));
  assert.equal(find(row, "tab-new"), undefined);
  assert.equal(find(row, "panel-files"), undefined);
  assert.equal(find(row, "panel-changes"), undefined);
});

test("right-side strip keeps new-tab, Files and Changes without tabs or tab navigation", async () => {
  const { row, calls } = await tabs("linux", "panels");

  assert.ok(find(row, "panel-files"));
  assert.ok(find(row, "panel-changes"));
  assert.equal(find(row, "tab-tab"), undefined);
  assert.ok(find(row, "tab-new"));
  assert.equal(row.attributes.on_scroll_wheel, undefined);

  find(row, "panel-changes").attributes.on_click[0]();

  assert.equal(calls[0][0], "layout.select");
  assert.equal(calls[0][1].child, "changes");
  assert.equal(calls[1][0], "layout.show");
});

test("bottom tabs still select a tab", async () => {
  const { row, calls } = await tabs("linux");

  find(row, "tab-tab").attributes.on_mouse_down[1]({ click_count: 1 }, { stop_propagation() {} });
  find(row, "tab-tab").attributes.on_mouse_up[1]();

  assert.equal(calls.length, 1);
  assert.equal(calls[0][0], "tab.select");
  assert.equal(calls[0][1].id, "tab");
});
