import assert from "node:assert/strict";
import test from "node:test";
import { WatcherLocations } from "./location.js";

const tab = { id: "tab", name: "2", index: 2, named: false };
const space = { id: "space", folder: "/work/repo", machine: null, tabs: [tab] };
const pane = { pane: "pane", terminal: "t1", tab: "tab" };
const process = { address: "t1", state: "live", argv: ["zsh"],
  foreground: { argv: ["fzz", "watch", "--", "test"], cwd: space.folder } };

function harness({ spaces = [space], panes = [pane], result = process } = {}) {
  const calls = [];
  const commands = [];
  const locations = new WatcherLocations({ spaces: () => spaces, panes: () => panes,
    core: async (args) => {
      calls.push(args);
      return { code: 0, stdout: JSON.stringify(result) };
    },
    run: (...args) => commands.push(args),
  });
  return { locations, calls, commands, setPanes: (next) => { panes = next; } };
}

test("finds watcher from foreground argv, not the shell's startup argv", async () => {
  const { locations, calls, commands } = harness();

  await locations.refresh();

  assert.deepEqual(calls, [["get", "t1", "--json"]]);
  assert.deepEqual(locations.forFolder(space.folder), [{ terminal: "t1", pane: "pane", tab: "tab", name: "watcher" }]);
  assert.deepEqual(commands, [["tab.rename", { id: "tab", name: "watcher" }]]);
  assert.equal(locations.unique(space.folder).terminal, "t1");
  assert.equal(locations.unique("/missing"), null);
});

test("renames an unnamed watcher tab once, but preserves custom names", async () => {
  const { locations, commands } = harness();
  await locations.refresh();
  await locations.refresh();
  assert.equal(commands.length, 1);

  const custom = harness({ spaces: [{ ...space, tabs: [{ ...tab, named: true, name: "Checks" }] }] });
  await custom.locations.refresh();
  assert.deepEqual(custom.commands, []);
  assert.equal(custom.locations.forFolder(space.folder)[0].name, "Checks");
});

test("accepts bare watcher commands and absolute binary paths", async () => {
  for (const argv of [["fzz"], ["/opt/bin/funzzy"], ["/opt/bin/fzz", "watch", "test"]]) {
    const { locations } = harness({ result: { ...process, foreground: { ...process.foreground, argv } } });

    await locations.refresh();

    assert.equal(locations.forFolder(space.folder).length, 1);
  }
});

test("ignores finite commands, shell text, stale metadata, and other folders", async () => {
  const invalid = [
    { ...process, state: "finished" }, { ...process, address: "other" },
    { ...process, foreground: null },
    { ...process, foreground: { ...process.foreground, cwd: "/work/elsewhere" } },
    ...[["fzz", "ctl", "status"], ["fzz", "run", "test"], ["echo", "fzz watch"], ["pi"], []]
      .map((argv) => ({ ...process, foreground: { ...process.foreground, argv } })),
  ];
  for (const result of invalid) {
    const { locations, commands } = harness({ result });

    await locations.refresh();

    assert.deepEqual(locations.forFolder(space.folder), []);
    assert.deepEqual(commands, []);
  }
});

test("never queries remote terminals or mod panes", async () => {
  for (const options of [{ spaces: [{ ...space, machine: "remote" }] },
    { panes: [{ ...pane, terminal: null }] }, { panes: [{ ...pane, tab: "missing" }] }]) {
    const { locations, calls } = harness(options);

    await locations.refresh();

    assert.deepEqual(calls, []);
    assert.deepEqual(locations.forFolder(space.folder), []);
  }
});

test("multiple watchers remain ambiguous and are not auto-renamed", async () => {
  const panes = [pane, { pane: "pane2", terminal: "t2", tab: "tab" }];
  const commands = [];
  const locations = new WatcherLocations({ spaces: () => [space], panes: () => panes,
    core: async (args) => ({ code: 0, stdout: JSON.stringify({ ...process, address: args[1] }) }),
    run: (...args) => commands.push(args),
  });

  await locations.refresh();

  assert.equal(locations.forFolder(space.folder).length, 2);
  assert.equal(locations.unique(space.folder), null);
  assert.deepEqual(commands, []);
});

test("failed or invalid metadata queries clear a previous location", async () => {
  for (const failure of [() => { throw new Error("offline"); },
    () => ({ code: 1, stdout: "" }), () => ({ code: 0, stdout: "not json" })]) {
    let fail = false;
    const locations = new WatcherLocations({ spaces: () => [space], panes: () => [pane], run: () => {},
      core: async () => fail ? failure() : ({ code: 0, stdout: JSON.stringify(process) }),
    });
    await locations.refresh();

    fail = true;
    await locations.refresh();

    assert.deepEqual(locations.forFolder(space.folder), []);
  }
});

test("closing a previously located pane clears its cached target", async () => {
  const { locations, setPanes } = harness();
  await locations.refresh();

  setPanes([]);
  assert.equal(locations.unique(space.folder), null);
  await locations.refresh();

  assert.deepEqual(locations.forFolder(space.folder), []);
});

test("closing a pane during discovery discards its old location", async () => {
  let resolve;
  let panes = [pane];
  const commands = [];
  const locations = new WatcherLocations({ spaces: () => [space], panes: () => panes,
    run: (...args) => commands.push(args),
    core: async () => new Promise((done) => { resolve = done; }),
  });
  const pending = locations.refresh();

  panes = [];
  resolve({ code: 0, stdout: JSON.stringify(process) });
  await pending;

  assert.deepEqual(locations.forFolder(space.folder), []);
  assert.deepEqual(commands, []);
});
