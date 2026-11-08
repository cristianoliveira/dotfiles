import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";
import { moveTabTo } from "../mods/tmux-compat/move-tab.js";

function element() {
  const callbacks = {};
  const node = new Proxy({ callbacks }, {
    get(target, name) {
      if (name === "callbacks") return callbacks;
      return (...args) => {
        if (name === "on_key_down") callbacks.key = args[0];
        return node;
      };
    },
  });
  return node;
}

async function prompt() {
  const calls = [];
  const handlers = {};
  const input = {
    text: "", value() { return this.text; },
    on(name, callback) { handlers[name] = callback; },
    focus() {},
  };
  const cx = { focus_handle: () => ({}), notify() { calls.push(["notify"]); } };
  const source = (await readFile(new URL("../mods/tmux-compat/move-tab-view.js", import.meta.url), "utf8"))
    .replace(/^import .*;$/gm, "")
    .replace("export class MoveTabMode", "globalThis.MoveTabMode = class MoveTabMode");
  const scope = {
    InputState: { new: () => input }, Input: { new: element }, moveTabTo,
    div: element, v_flex: element, h_flex: element, theme: () => ({}),
    spaces: () => [{ id: "space", tabs: [{ id: "one" }, { id: "two" }] }],
    run: (...args) => calls.push(args), closeOverlay: id => calls.push(["close", id]),
  };
  vm.runInNewContext(source, scope);
  const mode = new scope.MoveTabMode({ overlay: "prompt", target: { spaceId: "space", tabId: "two" } }, cx);
  return { mode, input, handlers, calls, cx };
}

test("submitting a valid position moves original tab and closes the prompt", async () => {
  const { input, handlers, calls, cx } = await prompt();
  input.text = "0";

  handlers.submit({}, cx);

  assert.deepEqual(calls, [["tab.move", { id: "two", index: 1 }], ["close", "prompt"]]);
});

test("invalid input keeps prompt open and explains valid range", async () => {
  const { mode, input, handlers, calls, cx } = await prompt();
  input.text = "2";

  handlers.submit({}, cx);

  assert.equal(mode.message, "Enter a position from 0 to 1.");
  assert.deepEqual(calls, [["notify"]]);
});

test("Escape cancels the prompt without moving any tab", async () => {
  const { mode, calls } = await prompt();
  const view = mode.render();

  view.callbacks.key({ key: "escape" }, { stop_propagation() {} });

  assert.deepEqual(calls, [["close", "prompt"]]);
});
