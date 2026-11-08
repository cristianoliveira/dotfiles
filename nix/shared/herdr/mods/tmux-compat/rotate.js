export async function rotateTabPanes({ focused, spaces, panes, appHome, exec, run }) {
  const before = focused();
  if (!before?.pane) return false;
  const space = spaces().find(space => space.id === before.space);
  if (!space?.tabs.some(tab => tab.id === before.tab)) return false;
  const ids = panes().filter(pane => pane.tab === before.tab).map(pane => pane.pane);
  if (ids.length < 2 || !ids.includes(before.pane)) return false;

  const context = { space: before.space, tab: before.tab, pane: before.pane, panes: ids, machine: space.machine ?? null };
  const result = await exec("python3", ["-I", `${appHome()}/mods/tmux-compat/rotate.py`, JSON.stringify(context)]);
  if (result.code !== 0) throw new Error(result.stderr?.trim() || "Pane rotation failed.");
  const target = JSON.parse(result.stdout);
  if (!ids.includes(target?.pane) || typeof target.changed !== "boolean") {
    throw new Error("Rotation returned an unexpected pane; focus was left unchanged.");
  }
  const current = focused();
  if (target.changed && current?.space === before.space && current.tab === before.tab && current.pane === before.pane) {
    run("pane.focus", { pane: target.pane });
  }
  return target.changed;
}
