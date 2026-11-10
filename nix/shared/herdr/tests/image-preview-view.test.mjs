import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";
import { imagePath, fitImage, previewAsset } from "../mods/image-preview/model.js";

function element() {
  const node = { handlers: {} };
  const builder = new Proxy(node, { get(target, name) {
    if (name in target) return target[name];
    if (name === "when") return (condition, apply) => condition ? apply(builder) : builder;
    return (...args) => { target.handlers[name] = args; return builder; };
  } });
  return builder;
}

async function viewer({ clipboard = "", result, options } = {}) {
  const path = new URL("../mods/image-preview/main.js", import.meta.url);
  const source = (await readFile(path, "utf8")).replace(/^import .*;$/gm, "")
    .replace("export default class ImagePreview", "globalThis.Preview = class ImagePreview");
  const calls = [];
  const closed = [];
  const tasks = [];
  const scope = {
    View: class {}, div: element, image: element, v_flex: element, h_flex: element,
    imagePath, fitImage, previewAsset, theme: () => ({}),
    window: { viewport_size: () => ({ width: 1200, height: 800 }) },
    Input: { new: element }, InputState: { new: ({ value }) => ({
      value: () => value, set_value: next => { value = next; }, on() {}, focus() {},
    }) },
    focused: () => ({ space: "mac/project", cwd: "/remote/project" }),
    spaces: () => [{ id: "mac/project", machine: "mac", folder: "/remote/project" }],
    machines: () => [{ name: null, layout: "ready" }, { name: "mac", layout: "ready" }],
    props: () => ({ overlay: "preview" }), closeOverlay: id => closed.push(id), appHome: () => "/app",
    exec: async (_command, args) => {
      calls.push(Array.from(args));
      if (args.includes("--clipboard")) return { code: 0, stdout: JSON.stringify({ path: clipboard }) };
      return result ?? { code: 0, stdout: JSON.stringify({ width: 1600, height: 800,
        path: `/app/image-previews/image-${"a".repeat(64)}.png` }) };
    },
  };
  vm.runInNewContext(source, scope, { filename: path.pathname });
  const mod = new scope.Preview();
  const cx = { focus_handle() { return { focus() {} }; }, notify() {}, stop_propagation() {}, spawn: task => tasks.push(task(cx)) };
  mod.init(options, cx);
  return { mod, cx, calls, closed, async settle() { for (let i = 0; i < tasks.length; i++) await tasks[i]; } };
}

test("copied image path opens on the source machine without sending terminal input", async () => {
  const v = await viewer({ clipboard: "/tmp/shot.png" });
  await v.settle();

  assert.equal(v.mod.preview.machine, "mac");
  assert.equal(v.mod.preview.source, "/tmp/shot.png");
  assert.equal(v.calls[1][v.calls[1].indexOf("--cwd") + 1], "/remote/project");
  assert.equal(v.calls[1][v.calls[1].indexOf("--machine") + 1], "mac");
  assert.equal(v.mod.render().handlers.w[0], 1200);
  assert.equal(v.mod.render().handlers.h[0], 800);
  assert.equal(v.mod.controls, false);
});

test("empty clipboard leaves a manual path field; local override does not inherit remote cwd", async () => {
  const v = await viewer({ options: { machine: "" } });
  await v.settle();

  assert.equal(v.mod.preview, null);
  assert.equal(v.calls.length, 1);
  v.mod.input.set_value("/tmp/image's $(touch NEVER).png");
  v.mod.load(v.cx);
  await v.settle();

  assert.equal(v.mod.preview.machine, "");
  assert.equal(v.calls[1][1], "/tmp/image's $(touch NEVER).png");
  assert.equal(v.calls[1][v.calls[1].indexOf("--cwd") + 1], "");
});

test("failed loads report error and Escape closes only the popup", async () => {
  const v = await viewer({ options: { path: "/missing.png" }, result: { code: 1, stderr: "File missing" } });
  await v.settle();

  assert.equal(v.mod.preview, null);
  assert.equal(v.mod.error, "File missing");
  v.mod.render().handlers.on_key_down[0]({ key: "escape" }, v.cx);
  assert.deepEqual(v.closed, ["preview"]);
});

test("editing controls can be reopened without closing the full-window image", async () => {
  const v = await viewer({ options: { path: "shot.png" } });
  await v.settle();

  v.mod.render().handlers.on_key_down[0]({ key: "e" }, v.cx);

  assert.equal(v.mod.controls, true);
  assert.equal(v.mod.preview.source, "shot.png");
});

test("dropping an image opens it locally even when source space is remote", async () => {
  const v = await viewer();
  await v.settle();

  v.mod.render().handlers.on_drop[0]({ paths: ["/tmp/dropped image.png"] }, v.cx);
  await v.settle();

  assert.equal(v.mod.preview.machine, "");
  assert.equal(v.mod.preview.source, "/tmp/dropped image.png");
  assert.equal(v.mod.controls, false);
});

test("changing machines clears the old preview and uses that machine's home", async () => {
  const v = await viewer({ options: { path: "shot.png" } });
  await v.settle();

  v.mod.selectMachine("", v.cx);

  assert.equal(v.mod.machine, "");
  assert.equal(v.mod.cwd, "");
  assert.equal(v.mod.preview, null);
});
