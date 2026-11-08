function rotatePair(before, ids, run) {
  // Two split leaves are horizontal or vertical. Exactly one direction toward
  // the other slot swaps them; the perpendicular direction is a no-op. Finish
  // before yielding. Do not probe focused(): its snapshot is turn-scoped.
  const incoming = ids.find(id => id !== before.pane);
  const directions = before.pane === ids[0] ? ["right", "down"] : ["left", "up"];
  for (const direction of directions) run("pane.swap", { direction });
  run("pane.focus", { pane: incoming });
}

export async function rotateTabPanes({ focused, spaces, panes, appHome, exec, run, nativePairs = true }) {
  const before = focused();
  if (!before?.pane) return false;
  const space = spaces().find(space => space.id === before.space);
  const tab = space?.tabs.find(tab => tab.id === before.tab);
  if (!tab) return false;
  const items = panes().filter(pane => pane.tab === before.tab);
  const ids = items.map(pane => pane.pane);
  if (ids.length < 2 || !ids.includes(before.pane)) return false;
  if (nativePairs && ids.length === 2 && ids[0] !== ids[1] && !tab.zoomed && !before.shown &&
      items.every(pane => pane.terminal && !pane.mod)) {
    rotatePair(before, ids, run);
    return true;
  }

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
