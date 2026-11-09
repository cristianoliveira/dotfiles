import assert from "node:assert/strict";
import test from "node:test";
import { WatcherStatus, watcherBinary, statusColor } from "./model.js";

const local = { id: "one", folder: "/work/project with 'quotes'", machine: null };
const capabilities = { schemaVersion: 1, methods: ["status"], instance: { token: "fz-one" } };
const success = (data) => ({ code: 0, stdout: JSON.stringify(data), stderr: "" });
const snapshot = (state = "passed", generation = 4) => ({ state, generation, failures: [] });

function harness(responses = [success(capabilities), success(snapshot())]) {
  let space = local;
  const calls = [];
  const status = new WatcherStatus({
    activeSpace: () => space,
    exec: async (...args) => {
      calls.push(args);
      const response = responses.shift();
      if (response instanceof Error) throw response;
      return typeof response === "function" ? response() : response;
    },
  });
  return { status, calls, select: (value) => { space = value; status.select(); } };
}

test("watcher status uses theme blue for running, green for passed, and red for failed", () => {
  const theme = { ansi4: "#268bd2", ansi2: "#859900", ansi1: "#dc322f", muted: "#586e75" };

  assert.equal(statusColor("running", theme), "#268bd2");
  assert.equal(statusColor("passed", theme), "#859900");
  assert.equal(statusColor("failed", theme), "#dc322f");
  for (const state of ["idle", "cancelled", "offline", "loading", "unsupported", "error", "remote", "no-project"]) {
    assert.equal(statusColor(state, theme), "#586e75");
  }
});

test("binary selection expands only an explicit home prefix and otherwise preserves literal paths", () => {
  assert.equal(watcherBinary(undefined, "/home/me"), "fzz");
  assert.equal(watcherBinary("~/.cargo/bin/fzz", "/home/my name"), "/home/my name/.cargo/bin/fzz");
  assert.equal(watcherBinary("/opt/tools/fzz", "/home/me"), "/opt/tools/fzz");
  assert.equal(watcherBinary("fzz; touch /tmp/not-run", "/home/me"), "fzz; touch /tmp/not-run");
});

test("explicit v2 binary is used for every query instead of the desktop PATH", async () => {
  const calls = [];
  const status = new WatcherStatus({ activeSpace: () => local, binary: "/home/me/.cargo/bin/fzz",
    exec: async (...args) => {
      calls.push(args);
      return success(args[1].at(-1) === "capabilities" ? capabilities : snapshot());
    },
  });

  await status.poll();

  assert.deepEqual(calls.map((args) => args[0]), ["/home/me/.cargo/bin/fzz", "/home/me/.cargo/bin/fzz"]);
  assert.equal(status.value.state, "passed");
});

test("queries only capabilities and status with explicit argv and project cwd", async () => {
  const { status, calls } = harness();

  await status.poll();

  assert.deepEqual(calls, ["capabilities", "status"].map((action) => [
    "fzz", ["ctl", "--format", "json", action], { cwd: local.folder },
  ]));
  assert.deepEqual(status.value, { state: "passed", generation: 4, failures: 0 });
});

for (const state of ["idle", "running", "passed", "failed", "cancelled"]) {
  test(`shows ${state} from the watcher, not the CLI exit code`, async () => {
    const data = { ...snapshot(state), failures: state === "failed" ? ["test failed"] : [] };
    const { status } = harness([success(capabilities), success(data)]);

    await status.poll();

    assert.deepEqual(status.value, { state, generation: 4, failures: data.failures.length });
  });
}

test("remote project queries use Herdr's machine transport and project cwd", async () => {
  const remote = { ...local, machine: "server" };
  const { status, calls, select } = harness();
  select(remote);

  await status.poll();

  assert.deepEqual(calls, ["capabilities", "status"].map((action) => [
    "fzz", ["ctl", "--format", "json", action], { cwd: remote.folder, on: "server" },
  ]));
  assert.deepEqual(status.value, { state: "passed", generation: 4, failures: 0 });
});

test("absent project contexts never execute commands", async () => {
  for (const space of [null, { ...local, folder: "" }]) {
    const { status, calls, select } = harness();
    select(space);

    await status.poll();

    assert.deepEqual(calls, []);
    assert.equal(status.value.state, "no-project");
  }
});

test("unreachable watcher clears a previous passing result", async () => {
  const { status } = harness([
    success(capabilities), success(snapshot()), { code: 1, stdout: "", stderr: "not reachable" },
  ]);
  await status.poll();

  await status.poll();

  assert.deepEqual(status.value, { state: "offline" });
});

test("remote transport failure reports offline", async () => {
  const remote = { ...local, machine: "server" };
  const { status, calls, select } = harness([{ code: 1, stdout: "", stderr: "offline" }]);
  select(remote);

  await status.poll();

  assert.deepEqual(status.value, { state: "offline" });
  assert.deepEqual(calls[0][2], { cwd: remote.folder, on: remote.machine });
});

test("missing executable is offline rather than a failed job", async () => {
  const { status } = harness([new Error("not installed")]);

  await status.poll();

  assert.deepEqual(status.value, { state: "offline" });
});

test("unsupported capabilities stop before requesting status", async () => {
  for (const data of [null, {}, { ...capabilities, schemaVersion: 2 }, { ...capabilities, methods: [] }]) {
    const { status, calls } = harness([success(data)]);

    await status.poll();

    assert.deepEqual(status.value, { state: "unsupported" });
    assert.equal(calls.length, 1);
  }
});

test("malformed JSON and malformed status never appear as passed", async () => {
  const invalid = [null, {}, snapshot("unexpected"), snapshot("passed", -1),
    { ...snapshot(), failures: "bad" }, { ...snapshot(), failures: [42] }];
  for (const response of [{ code: 0, stdout: "not json" }, ...invalid.map(success)]) {
    const { status } = harness([success(capabilities), response]);

    await status.poll();

    assert.deepEqual(status.value, { state: "error" });
  }
});

test("status transport failure is offline", async () => {
  const { status } = harness([success(capabilities), { code: 1, stdout: "" }]);

  await status.poll();

  assert.deepEqual(status.value, { state: "offline" });
});

test("project switch clears status immediately and ignores an old pending response", async () => {
  let resolve;
  const { status, select, calls } = harness([
    success(capabilities), () => new Promise((done) => { resolve = done; }),
    success(capabilities), success(snapshot("running", 1)),
  ]);
  const pending = status.poll();
  await new Promise((done) => setImmediate(done));

  select({ ...local, id: "two", folder: "/work/two" });
  assert.deepEqual(status.value, { state: "loading" });
  await status.poll();
  assert.equal(calls.length, 2, "only one request sequence may be in flight");
  resolve(success(snapshot("failed")));
  await pending;
  assert.deepEqual(status.value, { state: "loading" });

  await status.poll();
  assert.deepEqual(status.value, { state: "running", generation: 1, failures: 0 });
  assert.equal(calls[2][2].cwd, "/work/two");
});

test("switching remote machines at the same folder ignores the prior machine's late result", async () => {
  let resolve;
  const first = { ...local, machine: "server-one" };
  const second = { ...local, machine: "server-two" };
  const { status, select, calls } = harness([
    () => new Promise((done) => { resolve = done; }),
    success(capabilities), success(snapshot("running", 7)),
  ]);
  select(first);
  const pending = status.poll();

  select(second);
  resolve(success(capabilities));
  await pending;
  assert.deepEqual(status.value, { state: "loading" });

  await status.poll();

  assert.deepEqual(status.value, { state: "running", generation: 7, failures: 0 });
  assert.deepEqual(calls.map((call) => call[2].on), ["server-one", "server-two", "server-two"]);
});

test("selection is checked again after capabilities without requiring a render", async () => {
  let space = local;
  const calls = [];
  const status = new WatcherStatus({ activeSpace: () => space, exec: async (...args) => {
    calls.push(args);
    space = { ...local, id: "two", folder: "/work/two" };
    return success(capabilities);
  } });

  await status.poll();

  assert.equal(calls.length, 1);
  assert.deepEqual(status.value, { state: "loading" });
});

test("switching away and back still invalidates an old pending request", async () => {
  let resolve;
  const { status, select } = harness([() => new Promise((done) => { resolve = done; })]);
  const pending = status.poll();

  select({ ...local, id: "two" });
  select(local);
  resolve(success(capabilities));
  await pending;

  assert.deepEqual(status.value, { state: "loading" });
});

test("watcher restart can reset generation without preserving old success", async () => {
  const { status } = harness([
    success(capabilities), success(snapshot()),
    success({ ...capabilities, instance: { token: "fz-restarted" } }), success(snapshot("idle", 0)),
  ]);
  await status.poll();

  await status.poll();

  assert.deepEqual(status.value, { state: "idle", generation: 0, failures: 0 });
});
