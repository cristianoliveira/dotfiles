import assert from "node:assert/strict";
import test from "node:test";
import { RepeatSession, REPEAT_TIMEOUT_MS } from "../mods/tmux-compat/repeat.js";

function harness() {
  const timers = [];
  let closes = 0;
  const schedule = (ms, callback) => {
    const timer = { ms, callback, cancelled: false };
    timers.push(timer);
    return () => { timer.cancelled = true; };
  };
  const session = new RepeatSession(() => { closes++; });
  session.arm(schedule);
  return { session, schedule, timers, closed: () => closes };
}

test("repeat mode expires after the configured inactivity timeout", () => {
  const { session, timers, closed } = harness();

  assert.equal(timers[0].ms, REPEAT_TIMEOUT_MS);
  timers[0].callback();

  assert.equal(closed(), 1);
  assert.equal(session.active, false);
});

test("navigation keeps the user's previous/next order and renews timeout", () => {
  const { session, schedule, timers } = harness();

  assert.deepEqual(session.press("n", schedule), ["tab.prev"]);
  assert.equal(timers[0].cancelled, true);
  assert.deepEqual(session.press("p", schedule), ["tab.next"]);
  assert.equal(timers[1].cancelled, true);
  assert.equal(timers.length, 3);
});

test("pane movement supports vi letters with or without Ctrl", () => {
  const { session, schedule } = harness();

  for (const [key, direction] of [["h", "left"], ["j", "down"], ["k", "up"], ["l", "right"]]) {
    assert.deepEqual(session.press(key, schedule), ["pane.go", { direction }]);
    assert.deepEqual(session.press(`ctrl-${key}`, schedule), ["pane.go", { direction }]);
  }
});

test("Escape or an unrecognized key closes mode without executing anything", () => {
  for (const key of ["escape", "x", "ctrl-c", "ctrl-n", "ctrl-p", "cmd-q", "shift-n", "日本", "constructor"]) {
    const { session, schedule, closed, timers } = harness();

    assert.equal(session.press(key, schedule), null);
    assert.equal(closed(), 1);
    assert.equal(timers[0].cancelled, true);
  }
});

test("expired mode cannot run commands or rearm itself", () => {
  const { session, schedule, timers, closed } = harness();
  timers[0].callback();

  assert.equal(session.press("n", schedule), null);
  session.arm(schedule);
  session.finish();

  assert.equal(timers.length, 1);
  assert.equal(closed(), 1);
});

test("disposing cancels the timer without closing an already removed overlay", () => {
  const { session, schedule, timers, closed } = harness();

  session.dispose();
  session.dispose();

  assert.equal(timers[0].cancelled, true);
  assert.equal(closed(), 0);
  assert.equal(session.press("p", schedule), null);
});
