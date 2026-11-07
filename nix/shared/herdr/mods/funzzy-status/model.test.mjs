import assert from "node:assert/strict";
import test from "node:test";
import { WatcherStatus } from "./model.js";

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

test("remote and absent project contexts never execute local commands", async () => {
  for (const space of [null, { ...local, machine: "server" }, { ...local, folder: "" }]) {
    const { status, calls, select } = harness();
    select(space);

    await status.poll();

    assert.deepEqual(calls, []);
    assert.equal(status.value.state, space?.machine ? "remote" : "no-project");
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
