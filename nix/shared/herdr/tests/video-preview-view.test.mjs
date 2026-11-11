import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";

function element() {
  const node = { handlers: {} };
  const builder = new Proxy(node, { get(target, name) {
    if (name in target) return target[name];
    if (name === "when") return (condition, apply) => condition ? apply(builder) : builder;
    return (...args) => { target.handlers[name] = args; return builder; };
  } });
  return builder;
}

async function picker({ clipboard = "", machine = "", result, options } = {}) {
  const path = new URL("../mods/video-preview/main.js", import.meta.url);
  const source = (await readFile(path, "utf8")).replace(/^import .*;$/gm, "")
    .replace("export default class VideoPreview", "globalThis.Preview = class VideoPreview");
  const calls = [], closed = [], tasks = [];
  const scope = {
    View: class {}, div: element, v_flex: element, h_flex: element, Input: { new: element },
    InputState: { new: ({ value }) => ({ value: () => value, set_value: next => { value = next; }, focus() {}, on() {} }) },
    appHome: () => "/app", home: () => "/local/home", focused: () => ({ space: "source", cwd: "/source/work" }),
    spaces: () => [{ id: "source", machine, folder: "/source" }], theme: () => ({}),
    props: () => ({ overlay: "video" }), closeOverlay: id => closed.push(id),
    exec: async (_command, argv) => {
      const args = Array.from(argv);
      calls.push(args);
      const data = args.includes("--clipboard") ? { ok: true, path: clipboard } : result ?? { ok: true, state: "launched" };
      return { code: data.ok ? 0 : 1, stdout: JSON.stringify(data) };
    },
  };
  vm.runInNewContext(source, scope, { filename: path.pathname });
  const mod = new scope.Preview();
  const cx = { focus_handle() {}, notify() {}, stop_propagation() {}, spawn: task => tasks.push(task(cx)) };
  mod.init(options, cx);
  return { mod, cx, calls, closed, async settle() { for (let i = 0; i < tasks.length; i++) await tasks[i]; } };
}

test("copied video path requests local paused player and closes picker after launch", async () => {
  const p = await picker({ clipboard: "/tmp/demo.mp4" });
  await p.settle();

  assert.deepEqual(p.calls[1].slice(1), ["--cwd", "/source/work", "--", "/tmp/demo.mp4"]);
  assert.deepEqual(p.closed, ["video"]);
});

test("remote focused space never supplies a remote cwd for a local video", async () => {
  const p = await picker({ machine: "mac", options: { path: "demo.mp4" } });
  await p.settle();

  assert.equal(p.calls[0][2], "/local/home");
});

test("dropping a local path preserves literal characters and opens video", async () => {
  const p = await picker();
  await p.settle();
  p.mod.render().handlers.on_drop[0]({ paths: ["/tmp/video's $(touch NEVER).mp4"] }, p.cx);
  await p.settle();

  assert.equal(p.calls.at(-1).at(-1), "/tmp/video's $(touch NEVER).mp4");
  assert.deepEqual(p.closed, ["video"]);
});

test("player startup error stays visible instead of closing the picker", async () => {
  const p = await picker({ options: { path: "/tmp/bad.mp4" }, result: { ok: false, error: "Invalid video" } });
  await p.settle();

  assert.equal(p.mod.error, "Invalid video");
  assert.equal(p.mod.busy, false);
  assert.deepEqual(p.closed, []);
});

test("blank input does not request a player and Escape closes only the picker", async () => {
  const p = await picker();
  await p.settle();
  p.mod.open(p.cx);
  assert.match(p.mod.error, /local video path/);
  assert.equal(p.calls.length, 1);

  p.mod.render().handlers.on_key_down[0]({ key: "escape" }, p.cx);
  assert.deepEqual(p.closed, ["video"]);
});
