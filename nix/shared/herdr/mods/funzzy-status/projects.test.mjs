import assert from "node:assert/strict";
import test from "node:test";
import { ProjectWatchers } from "./projects.js";

const project = { id: "one", folder: "/work/one", name: "One", machine: null, active: true };
const other = { id: "two", folder: "/work/two", name: "Two", machine: null };

function harness(initial = [project, other]) {
  let spaces = initial;
  const values = new Map();
  const calls = [];
  const notifications = [];
  const monitors = new ProjectWatchers({
    spaces: () => spaces,
    notify: (message) => notifications.push(message),
    exec: async (_command, args, options) => {
      calls.push({ action: args.at(-1), folder: options.cwd });
      const value = values.get(options.cwd) ?? { state: "idle", generation: 0, token: "first" };
      if (value.offline) return { code: 1, stdout: "" };
      const data = args.at(-1) === "capabilities"
        ? { schemaVersion: 1, methods: ["status"], instance: { token: value.token } }
        : { state: value.state, generation: value.generation, failures: [] };
      return { code: 0, stdout: JSON.stringify(data) };
    },
  });
  return { monitors, calls, notifications, values, setSpaces: (next) => { spaces = next; monitors.sync(); } };
}

test("configured binary is forwarded to every project's monitor", async () => {
  const commands = [];
  const monitors = new ProjectWatchers({ spaces: () => [project, other], notify: () => {},
    binary: "/home/me/.cargo/bin/fzz",
    exec: async (command) => { commands.push(command); return { code: 1, stdout: "" }; },
  });

  await monitors.poll();

  assert.deepEqual(commands, ["/home/me/.cargo/bin/fzz", "/home/me/.cargo/bin/fzz"]);
});

test("one monitor per local project folder, shared by spaces and their agents", async () => {
  const { monitors, calls } = harness([project, { ...project, id: "duplicate" }, other,
    { ...other, machine: "remote" }, { ...other, folder: "" }]);

  await monitors.poll();

  assert.deepEqual(calls.filter((call) => call.action === "status").map((call) => call.folder),
    [project.folder, other.folder]);
  assert.equal(monitors.current().state, "idle");
});

test("notifies background project completion once and links to its space", async () => {
  const { monitors, values, notifications } = harness();
  values.set(other.folder, { state: "running", generation: 1, token: "first" });
  await monitors.poll();
  values.set(other.folder, { state: "failed", generation: 1, token: "first" });

  await monitors.poll();
  await monitors.poll();

  assert.deepEqual(notifications, [{
    title: "Funzzy · Two", body: "Run #1 failed", level: "error",
    action: { name: "space.select", args: { id: "two" } },
  }]);
});

test("notifies a new passing generation even if polling missed its running state", async () => {
  const { monitors, values, notifications } = harness([project]);
  await monitors.poll();
  values.set(project.folder, { state: "passed", generation: 2, token: "first" });

  await monitors.poll();

  assert.equal(notifications.length, 1);
  assert.equal(notifications[0].body, "Run #2 passed");
  assert.equal(notifications[0].level, "success");
});

test("initial terminal results, reconnects, and watcher restarts do not produce old alerts", async () => {
  const { monitors, values, notifications } = harness([project]);
  const passed = { state: "passed", generation: 8, token: "first" };
  values.set(project.folder, passed);
  await monitors.poll();
  values.set(project.folder, { offline: true });
  await monitors.poll();
  values.set(project.folder, passed);
  await monitors.poll();
  values.set(project.folder, { ...passed, generation: 1, token: "restarted" });

  await monitors.poll();

  assert.deepEqual(notifications, []);
});

test("unidentified legacy watchers show status but never generate completion alerts", async () => {
  const { monitors, values, notifications } = harness([project]);
  values.set(project.folder, { state: "running", generation: 1 });
  await monitors.poll();
  values.set(project.folder, { state: "failed", generation: 1 });

  await monitors.poll();

  assert.equal(monitors.current().state, "failed");
  assert.deepEqual(notifications, []);
});

test("closing a project removes its monitor and stops querying it", async () => {
  const { monitors, calls, setSpaces } = harness([project]);
  await monitors.poll();
  calls.length = 0;

  setSpaces([]);
  await monitors.poll();

  assert.deepEqual(calls, []);
  assert.deepEqual(monitors.current(), { state: "no-project" });
});

test("current indicator follows space selection without displaying another project's result", async () => {
  const { monitors, values, setSpaces } = harness();
  values.set(project.folder, { state: "passed", generation: 2, token: "first" });
  await monitors.poll();

  setSpaces([{ ...project, active: false }, { ...other, active: true }]);
  assert.equal(monitors.current().state, "idle");
  setSpaces([{ ...project, machine: "remote" }]);
  assert.deepEqual(monitors.current(), { state: "remote" });
  setSpaces([{ ...project, folder: "/work/new" }]);
  assert.deepEqual(monitors.current(), { state: "loading" });
});

test("repeated timer polls do not overlap a project's pending request", async () => {
  let resolve;
  let calls = 0;
  const monitors = new ProjectWatchers({ spaces: () => [project], notify: () => {},
    exec: async () => {
      calls += 1;
      return new Promise((done) => { resolve = done; });
    },
  });
  const pending = monitors.poll();

  await monitors.poll();
  assert.equal(calls, 1);
  resolve({ code: 1, stdout: "" });
  await pending;

  assert.equal(monitors.current().state, "offline");
});

test("unnamed background spaces use project basename in notifications", async () => {
  const { monitors, values, notifications } = harness([{ ...project, name: "", active: false }]);
  await monitors.poll();
  values.set(project.folder, { state: "passed", generation: 1, token: "first" });

  await monitors.poll();

  assert.deepEqual(monitors.current(), { state: "no-project" });
  assert.equal(notifications[0].title, "Funzzy · one");
});

test("closing a project while a poll is pending suppresses its notification", async () => {
  let resolve;
  let calls = 0;
  let spaces = [project];
  const notices = [];
  const monitors = new ProjectWatchers({ spaces: () => spaces, notify: (n) => notices.push(n),
    exec: async () => {
      calls += 1;
      if (calls === 1) return { code: 0, stdout: JSON.stringify({ schemaVersion: 1, methods: ["status"] }) };
      return new Promise((done) => { resolve = done; });
    },
  });
  const pending = monitors.poll();
  await new Promise((done) => setImmediate(done));

  spaces = [];
  monitors.sync();
  resolve({ code: 0, stdout: JSON.stringify({ state: "failed", generation: 1, failures: [] }) });
  await pending;

  assert.deepEqual(notices, []);
  assert.deepEqual(monitors.current(), { state: "no-project" });
});
