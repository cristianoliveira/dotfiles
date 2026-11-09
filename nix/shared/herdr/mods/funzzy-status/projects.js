import { WatcherStatus } from "./model.js";

function projectKey(space) {
  return JSON.stringify([space.machine ?? null, space.folder]);
}

export class ProjectWatchers {
  constructor({ spaces, exec, notify, binary = "fzz", remoteBinary = "fzz", locate = () => null }) {
    this.spaces = spaces;
    this.exec = exec;
    this.binary = binary;
    this.remoteBinary = remoteBinary;
    this.notify = notify;
    this.locate = locate;
    this.projects = new Map();
  }

  sync() {
    const contexts = new Map();
    for (const space of this.spaces()) {
      if (!space.folder) continue;
      const key = projectKey(space);
      if (!contexts.has(key)) contexts.set(key, space);
    }
    for (const key of this.projects.keys()) {
      if (!contexts.has(key)) this.projects.delete(key);
    }
    for (const [key, space] of contexts) {
      if (!this.projects.has(key)) {
        const machine = space.machine ?? null;
        // Machine + folder identity keeps matching spaces on one watcher without
        // conflating equal paths that live on different hosts.
        const monitor = new WatcherStatus({
          activeSpace: () => ({ id: key, folder: space.folder, machine }),
          exec: this.exec,
          binary: machine ? this.remoteBinary : this.binary,
        });
        this.projects.set(key, { machine, monitor });
      }
      this.projects.get(key).space = space;
    }
  }

  current() {
    const space = this.spaces().find((item) => item.active);
    if (!space?.folder) return { state: "no-project" };
    return this.projects.get(projectKey(space))?.monitor.value ?? { state: "loading" };
  }

  async poll() {
    this.sync();
    await Promise.all([...this.projects.entries()].map(async ([key, entry]) => {
      if (entry.polling) return;
      entry.polling = true;
      try {
        await entry.monitor.poll();
        this.sync();
        if (this.projects.get(key) !== entry) return;
        const { state, generation } = entry.monitor.value;
        const instance = entry.monitor.instance;
        if (!instance || generation === undefined) return;
        const previous = entry.previous;
        entry.previous = { state, generation, instance };
        // First observation (including a restart) establishes a silent baseline.
        if (!previous || previous.instance !== instance) return;
        if (state !== "passed" && state !== "failed") return;
        if (previous.generation === generation && previous.state === state) return;
        const location = entry.machine ? null : this.locate(entry.space.folder);
        this.notify({
          title: `Funzzy · ${entry.space.name || entry.space.folder.split("/").pop()}`,
          body: `Run #${generation} ${state}`,
          level: state === "failed" ? "error" : "success",
          action: location
            ? { name: "pane.focus", args: { terminal: location.terminal } }
            : { name: "space.select", args: { id: entry.space.id } },
        });
      } finally {
        entry.polling = false;
      }
    }));
  }
}
