export async function shrinkPaneHeight({ focused, spaces, panes, appHome, exec, run }) {
  const before = focused();
  if (!before?.pane) return false;
  const space = spaces().find(space => space.id === before.space);
  const tab = space?.tabs.find(tab => tab.id === before.tab);
  const ids = panes().filter(pane => pane.tab === before.tab).map(pane => pane.pane);
  if (!tab || ids.length < 2 || !ids.includes(before.pane)) return false;

  const context = { space: before.space, tab: before.tab, pane: before.pane, panes: ids, machine: space.machine ?? null };
  const result = await exec("python3", ["-I", `${appHome()}/mods/tmux-compat/rotate.py`, "--shrink-height", JSON.stringify(context)]);
  if (result.code !== 0) throw new Error(result.stderr?.trim() || "Pane resize failed.");
  const target = JSON.parse(result.stdout);
  if (target?.pane !== before.pane || typeof target.changed !== "boolean") {
    throw new Error("Pane resize returned an unexpected result; focus was left unchanged.");
  }
  const current = focused();
  const currentTab = spaces().find(space => space.id === before.space)?.tabs.find(tab => tab.id === before.tab);
  const unzoom = tab.zoomed && currentTab?.zoomed && current?.space === before.space &&
    current.tab === before.tab && current.pane === before.pane && current.shown === before.shown;
  if (unzoom) run("pane.zoom", { pane: before.pane });
  return target.changed || !!unzoom;
}
