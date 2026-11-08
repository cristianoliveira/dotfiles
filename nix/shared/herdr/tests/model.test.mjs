import assert from "node:assert/strict";
import test from "node:test";
import { filterProjects, projectCommand } from "../mods/project-picker/model.js";

const project = { label: "work/repo", folder: "/home/me/work/repo", spaceId: "local" };

test("filter matches fuzzy characters without changing discovery order", () => {
  const projects = [project, { label: "other/日本語", folder: "/other" }];

  assert.deepEqual(filterProjects(projects, "WKRP"), [project]);
  assert.deepEqual(filterProjects(projects, "日本"), [projects[1]]);
  assert.deepEqual(filterProjects(projects, ""), projects);
  assert.deepEqual(filterProjects(projects, "missing"), []);
});

test("selection reuses a live local space discovered through a symlink", () => {
  const spaces = [{ id: "local", machine: null, folder: "/alias" }];

  assert.deepEqual(projectCommand(project, spaces), ["space.select", { id: "local" }]);
});

test("selection rechecks spaces created after discovery", () => {
  const spaces = [{ id: "new", machine: null, folder: project.folder }];

  assert.deepEqual(projectCommand(project, spaces), ["space.select", { id: "new" }]);
});

test("new projects explicitly target the local machine, ignoring remote collisions", () => {
  const spaces = [{ id: "local", machine: "server", folder: project.folder }];

  assert.deepEqual(projectCommand(project, spaces), ["space.new", {
    name: project.label, folder: project.folder, machine: "",
  }]);
});

test("project search matches machine then project, including the local alias", () => {
  const remote = { ...project, machine: "mac", label: "work/dotfiles" };
  const local = { ...remote, machine: "" };

  assert.deepEqual(filterProjects([local, remote], "macdotf"), [remote]);
  assert.deepEqual(filterProjects([local, remote], "LOCALdotf"), [local]);
  assert.deepEqual(filterProjects([local, remote], "dotf"), [local, remote]);
});

test("remote selection reuses only spaces on the matching machine", () => {
  const remote = { ...project, machine: "mac", spaceId: "mac/open" };
  const spaces = [
    { id: "local", machine: null, folder: project.folder },
    { id: "mac/open", machine: "mac", folder: "/alias" },
  ];

  assert.deepEqual(projectCommand(remote, spaces), ["space.select", { id: "mac/open" }]);
  assert.deepEqual(projectCommand({ ...remote, spaceId: null }, spaces), ["space.new", {
    name: project.label, folder: project.folder, machine: "mac",
  }]);
  assert.deepEqual(projectCommand(remote, [{ id: "mac/new", machine: "mac", folder: project.folder }]),
    ["space.select", { id: "mac/new" }]);
});

test("empty selection does not issue any command", () => {
  assert.equal(projectCommand(undefined, []), null);
});
