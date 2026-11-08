import assert from "node:assert/strict";
import test from "node:test";
import { refreshProjects, restoreProjectCache, CACHE_TTL_MS } from "../mods/project-picker/discovery.js";

const project = (label, machine = "") => ({ label, folder: `/${label}`, machine });
const entry = (machine, updatedAt, projects) => ({ machine, updatedAt, projects, warnings: [] });
function deferred() {
  let resolve;
  const promise = new Promise(done => { resolve = done; });
  return { promise, resolve };
}

test("fresh per-machine caches render without scanning", async () => {
  const cache = [entry("", 100, [project("work/local")]), entry("mac", 100, [project("work/remote", "mac")])];
  const updates = [];

  await refreshProjects({ cache, machines: ["", "mac"], now: () => 101,
    scan: () => assert.fail("fresh projects must not be scanned"),
    publish: state => updates.push(state), persist: () => assert.fail("no cache writes needed"),
  });

  assert.deepEqual(updates[0].projects.map(p => p.label), ["work/local", "work/remote"]);
  assert.equal(updates.at(-1).loading, false);
});

test("expired caches render immediately and machines refresh progressively", async () => {
  const local = deferred();
  const remote = deferred();
  const cache = [entry("mac", 0, [project("work/old", "mac")])];
  const updates = [];
  const saved = [];

  const loading = refreshProjects({ cache, machines: ["", "mac"], now: () => CACHE_TTL_MS,
    scan: machine => machine ? remote.promise : local.promise,
    publish: state => updates.push(state), persist: value => saved.push(value),
  });
  assert.deepEqual(updates[0].projects.map(p => p.label), ["work/old"]);
  assert.equal(updates[0].loading, true);

  local.resolve({ projects: [project("work/local")], warnings: [] });
  await new Promise(resolve => setImmediate(resolve));
  assert.deepEqual(updates.at(-1).projects.map(p => p.label), ["work/local", "work/old"]);
  assert.equal(updates.at(-1).loading, true);

  remote.resolve({ projects: [project("work/new", "mac")], warnings: [] });
  await loading;
  assert.deepEqual(updates.at(-1).projects.map(p => p.label), ["work/local", "work/new"]);
  assert.equal(updates.at(-1).loading, false);
  assert.equal(saved.length, 2);
});

test("failed refresh keeps stale projects and timestamp, without blocking other machines", async () => {
  const cache = [entry("mac", 0, [project("work/stale", "mac")])];
  const updates = [];
  const saved = [];

  await refreshProjects({ cache, machines: ["", "mac"], now: () => CACHE_TTL_MS,
    scan: async machine => {
      if (machine) throw new Error("unreachable");
      return { projects: [project("work/local")], warnings: [] };
    }, publish: state => updates.push(state), persist: value => saved.push(value),
  });

  assert.deepEqual(updates.at(-1).projects.map(p => p.label), ["work/local", "work/stale"]);
  assert.match(updates.at(-1).warnings.join("\n"), /mac.*unreachable/);
  assert.equal(updates.at(-1).loading, false);
  assert.deepEqual(saved.map(value => value.machine), [""]);
  assert.equal(cache[0].updatedAt, 0);
});

test("cache restoration rejects corrupt entries and disconnected machines are not displayed", async () => {
  assert.deepEqual(restoreProjectCache(null), []);
  assert.deepEqual(restoreProjectCache({ version: 0, entries: [] }), []);
  const cache = restoreProjectCache({ version: 1, entries: [
    entry("mac", 100, [project("work/cached", "mac")]),
    entry("broken", 100, [{}]),
    { ...entry("bad-warnings", 100, []), warnings: [42] },
    { machine: "missing-fields" },
  ] });
  assert.equal(cache.length, 1);
  const updates = [];

  await refreshProjects({ cache, machines: [""], now: () => 101,
    scan: async () => ({ projects: [], warnings: [] }),
    publish: state => updates.push(state), persist() {},
  });

  assert.deepEqual(updates.at(-1).projects, []);
});

test("refresh limits concurrency and keeps machine order despite completion order", async () => {
  const names = ["", "mac", "maya", "rome", "last"];
  const waits = names.map(deferred);
  const started = [];
  const updates = [];

  const loading = refreshProjects({ cache: [], machines: names, now: () => 100,
    scan: machine => { started.push(machine); return waits[names.indexOf(machine)].promise; },
    publish: state => updates.push(state), persist() {},
  });
  assert.deepEqual(started, names.slice(0, 4));

  waits[3].resolve({ projects: [project("work/rome", "rome")], warnings: [] });
  await new Promise(resolve => setImmediate(resolve));
  assert.deepEqual(started, names);
  for (const index of [4, 2, 1, 0]) {
    waits[index].resolve({ projects: [project(`work/${index}`, names[index])], warnings: [] });
  }
  await loading;

  assert.deepEqual(updates.at(-1).projects.map(p => p.machine), names);
});

test("future cache timestamps trigger refresh instead of staying fresh indefinitely", async () => {
  let scans = 0;
  await refreshProjects({ cache: [entry("", 101, [])], machines: [""], now: () => 100,
    scan: async () => { scans++; return { projects: [], warnings: [] }; }, publish() {}, persist() {},
  });
  assert.equal(scans, 1);
});

test("refresh rejects malformed data without replacing a good cached entry", async () => {
  const updates = [];

  await refreshProjects({ cache: [entry("", 0, [project("work/safe")])], machines: [""], now: () => CACHE_TTL_MS,
    scan: async () => ({ projects: [{}], warnings: [] }),
    publish: state => updates.push(state), persist: () => assert.fail("bad data must not be cached"),
  });

  assert.equal(updates.at(-1).projects[0].label, "work/safe");
  assert.equal(updates.at(-1).warnings.length, 1);
});
