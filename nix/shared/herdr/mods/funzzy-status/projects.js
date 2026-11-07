import { WatcherStatus } from "./model.js";

export class ProjectWatchers {
  constructor({ spaces, exec, notify, binary = "fzz" }) {
    this.spaces = spaces;
    this.exec = exec;
    this.binary = binary;
    this.notify = notify;
    this.projects = new Map();
  }

  sync() {
    const local = new Map();
    for (const space of this.spaces()) {
      if (!space.machine && space.folder && !local.has(space.folder)) local.set(space.folder, space);
    }
    for (const folder of this.projects.keys()) {
      if (!local.has(folder)) this.projects.delete(folder);
    }
    for (const [folder, space] of local) {
      if (!this.projects.has(folder)) {
        // Folder identity keeps multiple spaces/agents on the same watcher.
        const monitor = new WatcherStatus({
          activeSpace: () => ({ id: folder, folder, machine: null }),
          exec: this.exec, binary: this.binary,
        });
        this.projects.set(folder, { monitor });
      }
      this.projects.get(folder).space = space;
    }
  }

  current() {
    const space = this.spaces().find((item) => item.active);
    if (space?.machine) return { state: "remote" };
    if (!space?.folder) return { state: "no-project" };
    return this.projects.get(space.folder)?.monitor.value ?? { state: "loading" };
  }

  async poll() {
    this.sync();
    await Promise.all([...this.projects.entries()].map(async ([folder, entry]) => {
      if (entry.polling) return;
      entry.polling = true;
      try {
        await entry.monitor.poll();
        this.sync();
        if (this.projects.get(folder) !== entry) return;
        const { state, generation } = entry.monitor.value;
        const instance = entry.monitor.instance;
        if (!instance || generation === undefined) return;
        const previous = entry.previous;
        entry.previous = { state, generation, instance };
        // First observation (including a restart) establishes a silent baseline.
        if (!previous || previous.instance !== instance) return;
        if (state !== "passed" && state !== "failed") return;
        if (previous.generation === generation && previous.state === state) return;
        this.notify({
          title: `Funzzy · ${entry.space.name || folder.split("/").pop()}`,
          body: `Run #${generation} ${state}`,
          level: state === "failed" ? "error" : "success",
          action: { name: "space.select", args: { id: entry.space.id } },
        });
      } finally {
        entry.polling = false;
      }
    }));
  }
}
