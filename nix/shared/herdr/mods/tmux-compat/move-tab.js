export function moveTab(snapshot, direction, run) {
  const space = snapshot.find(space => space.active);
  if (!space) return;

  const current = space.tabs.findIndex(tab => tab.active);
  if (current < 0) return;

  const target = current + direction;
  if (target < 0 || target >= space.tabs.length) return;

  run("tab.move", { id: space.tabs[current].id, index: target + 1 });
}
