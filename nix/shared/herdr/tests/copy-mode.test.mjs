import assert from "node:assert/strict";
import test from "node:test";
import { copyPlan } from "../mods/tmux-compat/copy.js";

const focus = { space: "s", pane: "p", terminal: "t3" };

test("copy mode opens a local viewer for a local or remote terminal without using the project's cwd", () => {
  for (const terminal of ["t3", "mac/t3"]) {
    const plan = copyPlan({ ...focus, terminal }, "/config/herdr", "/home/me");
    assert.equal(plan.cwd, "/home/me");
    assert.deepEqual(plan.command, ["python3", "/config/herdr/mods/tmux-compat/copy_mode.py"]);
    assert.deepEqual(plan.args, ["--terminal", terminal]);
    assert.deepEqual(plan.dependencies, ["python3", "hc", "nvim"]);
  }
});

test("copy mode refuses missing terminal focus and invalid addresses", () => {
  for (const invalid of [null, {}, { pane: "p" }, { ...focus, terminal: "--help" }, { ...focus, terminal: "t3; echo bad" }]) {
    assert.throws(() => copyPlan(invalid, "/config", "/home/me"), /Focus a terminal/);
  }
});
