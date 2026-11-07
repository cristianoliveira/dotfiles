function isWatcher(terminal, target) {
  const foreground = terminal?.foreground;
  const argv = foreground?.argv;
  if (terminal?.state !== "live" || terminal.address !== target.terminal) return false;
  if (foreground?.cwd !== target.folder || !Array.isArray(argv)) return false;
  const program = typeof argv[0] === "string" ? argv[0].split("/").pop() : "";
  // Only unambiguous watcher invocations. Never infer a process from its title.
  return ["fzz", "funzzy"].includes(program) && (argv.length === 1 || argv[1] === "watch");
}

export class WatcherLocations {
  constructor({ spaces, panes, core, run }) {
    this.spaces = spaces;
    this.panes = panes;
    this.core = core;
    this.run = run;
    this.locations = new Map();
    this.renamed = new Set();
  }

  targets() {
    const tabs = new Map();
    for (const space of this.spaces()) {
      if (space.machine || !space.folder) continue;
      for (const tab of space.tabs) tabs.set(tab.id, { folder: space.folder, tab });
    }
    return this.panes().filter((pane) => pane.terminal && tabs.has(pane.tab))
      .map((pane) => ({ pane: pane.pane, terminal: pane.terminal, ...tabs.get(pane.tab) }));
  }

  forFolder(folder) {
    const live = this.targets();
    return (this.locations.get(folder) ?? []).filter((location) => live.some((target) =>
      target.folder === folder && target.pane === location.pane && target.terminal === location.terminal
      && target.tab.id === location.tab));
  }

  unique(folder) {
    const matches = this.forFolder(folder);
    return matches.length === 1 ? matches[0] : null;
  }

  async refresh() {
    const matches = await Promise.all(this.targets().map(async (target) => {
      try {
        const result = await this.core(["get", target.terminal, "--json"]);
        if (result.code !== 0 || !isWatcher(JSON.parse(result.stdout), target)) return null;
        return target;
      } catch {
        return null;
      }
    }));
    const live = this.targets();
    const grouped = new Map();
    for (const match of matches) {
      if (!match) continue;
      const target = live.find((item) => item.terminal === match.terminal && item.pane === match.pane
        && item.tab.id === match.tab.id && item.folder === match.folder);
      if (!target) continue;
      if (!grouped.has(target.folder)) grouped.set(target.folder, []);
      grouped.get(target.folder).push(target);
    }
    for (const id of this.renamed) {
      if (!live.some((item) => item.tab.id === id)) this.renamed.delete(id);
    }
    this.locations = new Map([...grouped].map(([folder, targets]) => [folder, targets.map((target) => {
      const { tab } = target;
      if (targets.length === 1 && !tab.named && !this.renamed.has(tab.id)) {
        this.run("tab.rename", { id: tab.id, name: "watcher" });
        this.renamed.add(tab.id);
      }
      return { terminal: target.terminal, pane: target.pane, tab: tab.id,
        name: tab.named ? tab.name : this.renamed.has(tab.id) ? "watcher" : tab.name };
    })]));
  }
}
