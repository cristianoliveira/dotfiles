export function folderTabName(focus) {
  if (!focus?.tab || !focus.pane || !focus.terminal || !focus.cwd) return null;

  const folder = focus.cwd.replace(/\/+$/, "") || "/";
  const name = folder.slice(folder.lastIndexOf("/") + 1) || "/";
  return { id: focus.tab, name };
}
