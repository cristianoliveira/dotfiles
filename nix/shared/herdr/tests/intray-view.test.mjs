import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";
import { restoreState, observeEvents, dismissEvent, jumpCommand } from "../mods/intray/model.js";

const agent = (address, status, seq) => ({ address, status, seq, title: address, space_name: "Project", tab_name: "Work" });

async function intray() {
  const calls = [];
  const sharedState = new Map();
  const lists = new Map();
  let snapshot = [];
  let live = [];
  let options = {};
  let jumpError = null;
  function element() {
    const node = { handlers: {} };
    const builder = new Proxy(node, { get(target, name) {
      if (name in target) return target[name];
      if (name === "when") return (condition, apply) => condition ? apply(builder) : builder;
      return (...args) => { target.handlers[name] = args; return builder; };
    } });
    return builder;
  }
  const path = new URL("../mods/intray/main.js", import.meta.url);
  const source = (await readFile(path, "utf8"))
    .replace(/^import .*;$/gm, "")
    .replace("export default class Intray", "globalThis.Intray = class Intray");
  const scope = {
    View: class {}, div: element, v_flex: element, h_flex: element,
    v_virtual_list(id, count, height, key, render) {
      const list = element();
      list.count = count;
      list.keys = Array.from({ length: count }, (_, index) => key(index));
      list.items = render({ start: 0, end: count });
      lists.set(id, list);
      return list;
    },
    VirtualListScrollHandle: { new: () => ({ scroll_to_item() {} }) },
    restoreState, observeEvents, dismissEvent, jumpCommand,
    agents: () => snapshot, terminals: () => live, props: () => options, theme: () => ({}),
    shared: key => sharedState.get(key), setShared: (key, value) => sharedState.set(key, value),
    run: (...args) => { if (jumpError) throw jumpError; calls.push(args); },
    closeOverlay: id => calls.push(["close", id]),
    notify: message => calls.push(["notice", message.title]),
  };
  vm.runInNewContext(source, scope, { filename: path.pathname });
  const cx = { focus_handle: () => ({ focus() { calls.push(["focus"]); } }), notify() {}, stop_propagation() {} };
  return {
    calls, lists,
    setAgents(value) { snapshot = value; live = value.map(a => ({ address: a.address, state: "live" })); },
    setLive(value) { live = value; },
    failJump() { jumpError = new Error("offline"); },
    open(mode) { options = { mode, overlay: "intray" }; const view = new scope.Intray(); view.init({}, cx); return view; },
    press(view, key) { view.render().handlers.on_key_down[0]({ key, keystroke: key }, cx); },
    state() { return restoreState(sharedState.get("intray.state")); },
  };
}

test("background observer captures events while the intray list is closed", async () => {
  const app = await intray();
  app.setAgents([agent("one", "working", 1)]);
  const observer = app.open("observer");
  observer.render();

  app.setAgents([agent("one", "done", 2)]);
  observer.render();
  const view = app.open();
  view.render();

  assert.equal(app.state().events.length, 1);
  assert.equal(app.lists.get("intray-events").count, 1);
});

test("opening intray selects newest event and Enter jumps to its terminal and marks it read", async () => {
  const app = await intray();
  app.setAgents([agent("old", "done", 1), agent("new", "blocked", 2)]);
  const view = app.open();

  app.press(view, "enter");

  assert.ok(app.calls.some(call => call[0] === "focus"));
  const command = app.calls.find(call => call[0] === "agent.focus");
  assert.equal(command[1].terminal, "new");
  assert.deepEqual(app.calls.at(-1), ["close", "intray"]);
  assert.deepEqual(app.state().events.map(event => event.address), ["old"]);
});

test("jump marks only the selected message read and does not reappear on reopening", async () => {
  const app = await intray();
  const observer = app.open("observer");
  app.setAgents([agent("one", "done", 1)]);
  observer.render();
  app.setAgents([agent("one", "working", 2)]);
  observer.render();
  app.setAgents([agent("one", "blocked", 3)]);
  const view = app.open();

  app.press(view, "enter");
  app.setAgents([agent("one", "idle", 4)]);
  observer.render();
  const next = app.open();
  next.render();

  assert.equal(app.state().events.length, 1);
  assert.equal(app.state().events[0].status, "done");
  app.press(next, "enter");
  app.open().render();
  assert.equal(app.state().events.length, 0);
});

test("a failed jump leaves its event unread and keeps intray open", async () => {
  const app = await intray();
  app.setAgents([agent("one", "done", 1)]);
  app.failJump();
  const view = app.open();

  app.press(view, "enter");

  assert.equal(app.state().events.length, 1);
  assert.equal(app.calls.some(call => call[0] === "close"), false);
  assert.deepEqual(app.calls.at(-1), ["notice", "Could not jump"]);
});

test("j/k and arrows navigate the flat list and Escape cancels", async () => {
  const app = await intray();
  app.setAgents([agent("old", "done", 1), agent("new", "blocked", 2)]);
  const view = app.open();

  app.press(view, "j");
  app.press(view, "enter");

  assert.equal(app.calls.find(call => call[0] === "agent.focus")[1].terminal, "old");
  const next = app.open();
  app.press(next, "down");
  app.press(next, "k");
  app.press(next, "up");
  app.press(next, "escape");
  assert.deepEqual(app.calls.at(-1), ["close", "intray"]);
});

test("clicking a flat-list row jumps to and reads that exact event", async () => {
  const app = await intray();
  app.setAgents([agent("old", "done", 1), agent("new", "blocked", 2)]);
  app.open().render();
  const list = app.lists.get("intray-events");

  list.handlers.on_item_click[0](list.keys[1]);

  assert.equal(app.calls.find(call => call[0] === "agent.focus")[1].terminal, "old");
  assert.deepEqual(app.state().events.map(event => event.address), ["new"]);
});

test("manual selection stays on the same event when newer events arrive", async () => {
  const app = await intray();
  app.setAgents([agent("old", "done", 1), agent("new", "blocked", 2)]);
  const view = app.open();
  app.press(view, "down");

  app.setAgents([agent("old", "done", 1), agent("new", "blocked", 2), agent("latest", "done", 3)]);
  app.press(view, "enter");

  assert.equal(app.calls.find(call => call[0] === "agent.focus")[1].terminal, "old");
});

test("dismissed events stay dismissed when observer and popup render again", async () => {
  const app = await intray();
  app.setAgents([agent("one", "done", 1)]);
  const observer = app.open("observer");
  observer.render();
  const view = app.open();

  app.press(view, "d");
  observer.render();
  app.open().render();

  assert.equal(app.state().events.length, 0);
  assert.equal(app.calls.some(call => call[0] === "agent.focus"), false);
});

test("ended terminals remain unread when a jump cannot be made", async () => {
  const app = await intray();
  app.setAgents([agent("old", "done", 1)]);
  const view = app.open();
  view.render();
  app.setLive([]);

  app.press(view, "enter");

  assert.equal(app.calls.some(call => call[0] === "agent.focus" || call[0] === "close"), false);
  assert.deepEqual(app.calls.at(-1), ["notice", "Terminal unavailable"]);
  assert.equal(app.state().events.length, 1);
});

test("empty intray navigation is harmless and later events appear", async () => {
  const app = await intray();
  const view = app.open();
  for (const key of ["j", "k", "up", "down", "enter"]) app.press(view, key);

  app.setAgents([agent("one", "done", 1)]);
  app.press(view, "enter");

  assert.equal(app.calls.find(call => call[0] === "agent.focus")[1].terminal, "one");
});
