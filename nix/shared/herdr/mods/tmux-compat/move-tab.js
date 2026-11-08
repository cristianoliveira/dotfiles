export function moveTabTo(snapshot, target, value, run) {
  const space = snapshot.find(space => space.id === target.spaceId);
  if (!space?.tabs.some(tab => tab.id === target.tabId)) {
    return "The original tab is no longer available. Cancel and try again.";
  }

  const position = Number(value);
  if (!/^\d+$/.test(value) || !Number.isSafeInteger(position) || position >= space.tabs.length) {
    return `Enter a position from 0 to ${space.tabs.length - 1}.`;
  }

  run("tab.move", { id: target.tabId, index: position + 1 });
  return null;
}

export function moveTab(snapshot, direction, run) {
  const space = snapshot.find(space => space.active);
  if (!space) return;

  const current = space.tabs.findIndex(tab => tab.active);
  if (current < 0) return;

  const target = current + direction;
  if (target < 0 || target >= space.tabs.length) return;

  run("tab.move", { id: space.tabs[current].id, index: target + 1 });
}
