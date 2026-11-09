import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";
import { restoreState, observeEvents, dismissEvent, dismissEvents, jumpCommand, filterEvents } from "../mods/intray/model.js";

const agent = (address, status, seq) => ({ address, status, seq, title: address, space_name: "Project", tab_name: "Work" });

async function intray() {
  const calls = [];
  const sharedState = new Map();
  const lists = new Map();
  let snapshot = [];
  let live = [];
  let options = {};
  let jumpError = null;
  let stopped = 0;
  function element() {
    const node = { handlers: {} };
    const builder = new Proxy(node, { get(target, name) {
      if (name in target) return target[name];
      if (name === "child") return child => { (target.children ??= []).push(child); return builder; };
      if (name === "children") return children => { target.children = children; return builder; };
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
    Input: { new: element }, Button: { new: element }, Tabs: { new: element }, Tab: { new: element },
    InputState: { new: () => {
      let value = "";
      const handlers = {};
      return { handlers, on: (name, callback) => { handlers[name] = callback; }, value: () => value,
        focus() { calls.push(["focus"]); }, type(text, cx) { value = text; handlers.change({}, cx); } };
    } },
    restoreState, observeEvents, dismissEvent, dismissEvents, jumpCommand, filterEvents,
    agents: () => snapshot, terminals: () => live, props: () => options, theme: () => ({}),
    shared: key => sharedState.get(key), setShared: (key, value) => sharedState.set(key, value),
    run: (...args) => { if (jumpError) throw jumpError; calls.push(args); },
    closeOverlay: id => calls.push(["close", id]),
    notify: message => calls.push(["notice", message.title]),
  };
  vm.runInNewContext(source, scope, { filename: path.pathname });
  const cx = { focus_handle: () => ({ focus() { calls.push(["focus"]); } }), notify() {}, stop_propagation() { stopped++; } };
  return {
    calls, lists, stopped: () => stopped,
    setAgents(value) { snapshot = value; live = value.map(a => ({ address: a.address, state: "live" })); },
    setLive(value) { live = value; },
    failJump() { jumpError = new Error("offline"); },
    open(mode) { options = { mode, overlay: "intray" }; const view = new scope.Intray(); view.init({}, cx); return view; },
    press(view, key) {
      const root = view.render();
      if (key === "enter") view.input.handlers.submit({}, cx);
      else root.handlers.on_key_down[0]({ key, keystroke: key }, cx);
    },
    search(view, text) { view.input.type(text, cx); view.render(); },
    tab(view, label) {
      function find(node) {
        if (node?.handlers?.on_click && renderedText(node).startsWith(`${label} (`)) return node;
        return Array.isArray(node?.children) ? node.children.map(find).find(Boolean) : undefined;
      }
      const button = find(view.render());
      assert.ok(button, `Missing status tab: ${label}`);
      button.handlers.on_click[0]({}, cx);
      view.render();
    },
    button(view, label) {
      function find(node) {
        if (node?.handlers?.on_click && renderedText(node) === label) return node;
        return Array.isArray(node?.children) ? node.children.map(find).find(Boolean) : undefined;
      }
      const button = find(view.render());
      assert.ok(button, `Missing button: ${label}`);
      return button;
    },
    click(view, label) {
      const button = this.button(view, label);
      assert.notEqual(button.handlers.disabled?.[0], true);
      button.handlers.on_click[0]({}, cx);
      view.render();
    },
    state() { return restoreState(sharedState.get("intray.state")); },
  };
}

function renderedText(node) {
  if (typeof node === "string") return node;
  return Array.isArray(node?.children) ? node.children.map(renderedText).join(" ") : "";
}

test("search distinguishes an empty queue from no matches and shows visible versus unread counts", async () => {
  const app = await intray();
  const view = app.open();
  assert.match(renderedText(view.render()), /No unread events/);
  app.setAgents([agent("one", "done", 1), agent("two", "blocked", 2)]);
  app.search(view, "one");
  assert.match(renderedText(view.render()), /1 of 2 unread/);

  app.search(view, "absent");

  assert.match(renderedText(view.render()), /No matching notifications/);
  assert.match(renderedText(view.render()), /0 of 2 unread/);
  assert.equal(app.state().events.length, 2);
});

test("status tabs show unread counts and switching does not mark events read", async () => {
  const app = await intray();
  app.setAgents([agent("old", "done", 1), agent("new", "blocked", 2)]);
  const view = app.open();
  assert.match(renderedText(view.render()), /All \(2\).*Finished \(1\).*Needs input \(1\)/);

  app.tab(view, "Finished");

  assert.equal(app.lists.get("intray-events").count, 1);
  assert.equal(app.state().events.length, 2);
  app.press(view, "enter");
  assert.equal(app.calls.find(call => call[0] === "agent.focus")[1].terminal, "old");
  assert.deepEqual(app.state().events.map(event => event.address), ["new"]);
});

test("status tabs retain search, reset selection and restore results when returning to All", async () => {
  const app = await intray();
  app.setAgents([agent("match-old", "done", 1), agent("match-new", "blocked", 2), agent("other", "done", 3)]);
  const view = app.open();
  view.render();
  app.search(view, "match");
  app.press(view, "down");

  app.tab(view, "Finished");
  assert.equal(app.lists.get("intray-events").count, 1);
  assert.equal(view.input.value(), "match");
  app.tab(view, "All");
  assert.equal(app.lists.get("intray-events").count, 2);
  app.press(view, "enter");

  assert.equal(app.calls.find(call => call[0] === "agent.focus")[1].terminal, "match-new");
});

test("empty status tabs cannot jump or dismiss events in another status", async () => {
  const app = await intray();
  app.setAgents([agent("finished", "done", 1)]);
  const view = app.open();

  app.tab(view, "Needs input");
  app.press(view, "enter");
  app.press(view, "ctrl-d");

  assert.equal(app.state().events.length, 1);
  assert.equal(app.calls.some(call => call[0] === "agent.focus" || call[0] === "close"), false);
  app.tab(view, "All");
  assert.equal(app.lists.get("intray-events").count, 1);
});

test("Tab and Ctrl-h/l cycle status tabs in both directions with wrapping and preserve search", async () => {
  const app = await intray();
  app.setAgents([agent("match-finished", "done", 1), agent("match-blocked", "blocked", 2)]);
  const view = app.open();
  view.render();
  app.search(view, "match");
  for (const key of ["tab", "tab", "ctrl-l"]) app.press(view, key);
  view.render();
  assert.equal(app.lists.get("intray-events").count, 2);
  app.press(view, "shift-tab");
  app.press(view, "ctrl-h");
  assert.equal(view.input.value(), "match");

  app.press(view, "enter");

  assert.equal(app.calls.find(call => call[0] === "agent.focus")[1].terminal, "match-finished");
  assert.equal(app.state().events.length, 1);
});

test("Ctrl-1/2/3 directly select All, Finished and Needs input without clearing search", async () => {
  for (const [key, address] of [["ctrl-1", "match-blocked"], ["ctrl-2", "match-finished"], ["ctrl-3", "match-blocked"]]) {
    const app = await intray();
    app.setAgents([agent("match-finished", "done", 1), agent("match-blocked", "blocked", 2), agent("other", "done", 3)]);
    const view = app.open();
    view.render();
    app.search(view, "match");
    app.tab(view, "Finished");

    app.press(view, key);
    assert.equal(view.input.value(), "match");
    assert.equal(app.state().events.length, 3);
    app.press(view, "enter");

    assert.equal(app.calls.find(call => call[0] === "agent.focus")[1].terminal, address);
  }
});

test("Ctrl-h wraps from All to Needs input and Ctrl-d dismisses only that status", async () => {
  const app = await intray();
  app.setAgents([agent("finished", "done", 1), agent("blocked", "blocked", 2)]);
  const view = app.open();

  app.press(view, "ctrl-h");
  app.press(view, "ctrl-d");

  assert.deepEqual(app.state().events.map(event => event.address), ["finished"]);
});

test("dismiss all requires confirmation and clears all statuses despite search filters", async () => {
  const app = await intray();
  app.setAgents([agent("one", "done", 1), agent("two", "blocked", 2)]);
  const view = app.open();
  view.render();
  app.search(view, "one");
  app.tab(view, "Finished");

  app.click(view, "Dismiss all");

  assert.equal(app.state().events.length, 2);
  assert.match(renderedText(view.render()), /Dismiss 2 unread across all statuses\/search/);
  app.click(view, "Confirm · Ctrl+Enter");
  assert.deepEqual(app.state().events, []);
  assert.equal(app.calls.some(call => call[0] === "agent.focus" || call[0] === "close"), false);
  app.open().render();
  assert.deepEqual(app.state().events, []);
});

test("cancel and Escape leave the unread queue unchanged and do not close the picker", async () => {
  for (const cancel of ["button", "escape"]) {
    const app = await intray();
    app.setAgents([agent("one", "done", 1)]);
    const view = app.open();
    app.click(view, "Dismiss all");

    if (cancel === "button") app.click(view, "Cancel");
    else app.press(view, "escape");

    assert.equal(app.state().events.length, 1);
    assert.equal(app.calls.some(call => call[0] === "close"), false);
    assert.ok(app.button(view, "Dismiss all"));
  }
});

test("new arrivals during confirmation survive bulk dismissal", async () => {
  const app = await intray();
  app.setAgents([agent("old", "done", 1)]);
  const view = app.open();
  app.click(view, "Dismiss all");
  app.setAgents([agent("old", "done", 1), agent("new", "blocked", 2)]);
  view.render();

  app.press(view, "ctrl-enter");

  assert.deepEqual(app.state().events.map(event => event.address), ["new"]);
});

test("confirmation does not delete replacements when reviewed events were dismissed elsewhere", async () => {
  const app = await intray();
  app.setAgents([agent("old", "done", 1)]);
  const first = app.open();
  app.click(first, "Dismiss all");
  const second = app.open();
  app.press(second, "ctrl-d");
  app.setAgents([agent("old", "done", 1), agent("new", "blocked", 2)]);
  first.render();

  assert.equal(app.button(first, "Confirm · Ctrl+Enter").handlers.disabled[0], true);
  app.press(first, "ctrl-enter");

  assert.deepEqual(app.state().events.map(event => event.address), ["new"]);
});

test("plain Enter, single-dismiss and row clicks cannot act behind the confirmation", async () => {
  const app = await intray();
  app.setAgents([agent("one", "done", 1)]);
  const view = app.open();
  app.click(view, "Dismiss all");

  app.press(view, "enter");
  app.press(view, "ctrl-d");
  const list = app.lists.get("intray-events");
  list.handlers.on_item_click[0](list.keys[0]);

  assert.equal(app.state().events.length, 1);
  assert.equal(app.calls.some(call => call[0] === "agent.focus" || call[0] === "close"), false);
});

test("Ctrl-Enter outside confirmation is consumed without jumping or dismissing", async () => {
  const app = await intray();
  app.setAgents([agent("one", "done", 1)]);
  const view = app.open();

  app.press(view, "ctrl-enter");

  assert.equal(app.stopped(), 1);
  assert.equal(app.state().events.length, 1);
  assert.equal(app.calls.some(call => call[0] === "agent.focus" || call[0] === "close"), false);
});

test("Ctrl-Shift-d then Ctrl-Enter dismisses all without a mouse, including hidden results", async () => {
  const app = await intray();
  app.setAgents([agent("one", "done", 1), agent("two", "blocked", 2)]);
  const view = app.open();
  view.render();
  assert.match(renderedText(view.render()), /Ctrl\+Shift\+D/);
  app.search(view, "absent");
  app.tab(view, "Finished");

  app.press(view, "ctrl-shift-d");

  assert.equal(app.state().events.length, 2);
  assert.match(renderedText(view.render()), /Dismiss 2 unread/);
  app.press(view, "ctrl-enter");
  assert.deepEqual(app.state().events, []);
  assert.equal(app.calls.some(call => call[0] === "agent.focus" || call[0] === "close"), false);
});

test("Escape cancels keyboard bulk-dismiss and key repeat never expands the reviewed set", async () => {
  const app = await intray();
  app.setAgents([agent("old", "done", 1)]);
  const view = app.open();
  app.press(view, "ctrl-shift-d");
  app.press(view, "escape");
  assert.equal(app.state().events.length, 1);
  assert.equal(app.calls.some(call => call[0] === "close"), false);
  app.press(view, "ctrl-shift-d");
  app.setAgents([agent("old", "done", 1), agent("new", "blocked", 2)]);

  app.press(view, "ctrl-shift-d");
  app.press(view, "ctrl-enter");

  assert.deepEqual(app.state().events.map(event => event.address), ["new"]);
});

test("keyboard bulk-dismiss on an empty queue is consumed without opening confirmation", async () => {
  const app = await intray();
  const view = app.open();

  app.press(view, "ctrl-shift-d");

  assert.equal(app.stopped(), 1);
  assert.doesNotMatch(renderedText(view.render()), /Confirm · Ctrl\+Enter/);
  assert.equal(app.state().events.length, 0);
});

test("dismiss all is disabled when there are no unread notifications", async () => {
  const app = await intray();
  const view = app.open();

  assert.equal(app.button(view, "Dismiss all").handlers.disabled[0], true);
});

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

test("Ctrl-j/k and arrows navigate the flat list and Escape cancels", async () => {
  const app = await intray();
  app.setAgents([agent("old", "done", 1), agent("new", "blocked", 2)]);
  const view = app.open();

  app.press(view, "ctrl-j");
  app.press(view, "enter");

  assert.equal(app.calls.find(call => call[0] === "agent.focus")[1].terminal, "old");
  const next = app.open();
  app.press(next, "down");
  app.press(next, "ctrl-k");
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

  app.press(view, "ctrl-d");
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

test("typing filters without reading notifications and Enter jumps only to a visible match", async () => {
  const app = await intray();
  app.setAgents([agent("older", "done", 1), agent("newer", "blocked", 2)]);
  const view = app.open();
  view.render();

  app.search(view, "older");

  assert.equal(app.state().events.length, 2);
  assert.equal(app.lists.get("intray-events").count, 1);
  app.press(view, "enter");
  assert.equal(app.calls.find(call => call[0] === "agent.focus")[1].terminal, "older");
  assert.deepEqual(app.state().events.map(event => event.address), ["newer"]);
});

test("changing search resets a hidden selection and filtered clicks read the exact event", async () => {
  const app = await intray();
  app.setAgents([agent("old", "done", 1), agent("middle", "done", 2), agent("new", "blocked", 3)]);
  const view = app.open();
  app.press(view, "down");

  app.search(view, "old");
  const list = app.lists.get("intray-events");
  list.handlers.on_item_click[0](list.keys[0]);

  assert.equal(app.calls.find(call => call[0] === "agent.focus")[1].terminal, "old");
  assert.deepEqual(app.state().events.map(event => event.address), ["new", "middle"]);
});

test("no matches cannot jump or dismiss hidden notifications and clearing restores them", async () => {
  const app = await intray();
  app.setAgents([agent("one", "done", 1)]);
  const view = app.open();
  view.render();
  app.search(view, "absent");

  app.press(view, "enter");
  app.press(view, "ctrl-d");
  assert.equal(app.state().events.length, 1);
  assert.equal(app.calls.some(call => call[0] === "agent.focus" || call[0] === "close"), false);
  app.search(view, "");
  assert.equal(app.lists.get("intray-events").count, 1);
  app.press(view, "escape");
  assert.equal(app.state().events.length, 1);
});

test("plain d/j/k are available for typing; Ctrl-d dismisses only the filtered event", async () => {
  const app = await intray();
  app.setAgents([agent("docs", "done", 1), agent("new", "blocked", 2)]);
  const view = app.open();
  for (const key of ["d", "j", "k"]) app.press(view, key);
  assert.equal(app.state().events.length, 2);
  assert.equal(app.stopped(), 0);

  app.search(view, "docs");
  app.press(view, "ctrl-d");

  assert.deepEqual(app.state().events.map(event => event.address), ["new"]);
  assert.equal(app.calls.some(call => call[0] === "agent.focus"), false);
});

test("a new query resets selection to its first result even if the previous selection still matches", async () => {
  const app = await intray();
  app.setAgents([agent("old", "done", 1), agent("new", "done", 2)]);
  const view = app.open();
  app.press(view, "down");

  app.search(view, "Project");
  app.press(view, "enter");

  assert.equal(app.calls.find(call => call[0] === "agent.focus")[1].terminal, "new");
});

test("filtered navigation retains the selected event when new matching notifications arrive", async () => {
  const app = await intray();
  app.setAgents([agent("match-old", "done", 1), agent("match-new", "blocked", 2)]);
  const view = app.open();
  view.render();
  app.search(view, "match");
  app.press(view, "ctrl-j");
  app.setAgents([agent("match-old", "done", 1), agent("match-new", "blocked", 2), agent("match-latest", "done", 3)]);

  app.press(view, "enter");

  assert.equal(app.calls.find(call => call[0] === "agent.focus")[1].terminal, "match-old");
});

test("empty intray navigation is harmless and later events appear", async () => {
  const app = await intray();
  const view = app.open();
  for (const key of ["ctrl-j", "ctrl-k", "up", "down", "enter"]) app.press(view, key);

  app.setAgents([agent("one", "done", 1)]);
  app.press(view, "enter");

  assert.equal(app.calls.find(call => call[0] === "agent.focus")[1].terminal, "one");
});
