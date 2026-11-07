function observeItems(history, items) {
  const live = new Set(items.map((item) => item.id));
  const previous = history.filter((id) => live.has(id));
  const current = items.find((item) => item.active)?.id;
  if (!current) return previous;

  return [current, ...previous.filter((id) => id !== current)].slice(0, 2);
}

export function observeSpaces(history, spaces) {
  return observeItems(history, spaces);
}

export function lastSpace(history) {
  return history[1] ?? null;
}

export function observeTabs(history, spaces) {
  const next = {};
  for (const space of spaces) {
    const tabs = space.tabs.map((tab) => ({ id: tab.id, active: space.active && tab.active }));
    const visits = observeItems(history[space.id] ?? [], tabs);
    if (visits.length) next[space.id] = visits;
  }
  return next;
}

export function lastTab(history, spaceId) {
  return history[spaceId]?.[1] ?? null;
}

export function observeRecentTabs(history, spaces) {
  const live = new Map(spaces.map(space => [space.id, new Set(space.tabs.map(tab => tab.id))]));
  const previous = history.filter(visit => live.get(visit.space)?.has(visit.tab));
  const space = spaces.find(space => space.active);
  const tab = space?.tabs.find(tab => tab.active);
  if (!tab) return previous;

  return [{ space: space.id, tab: tab.id }, ...previous.filter(visit =>
    visit.space !== space.id || visit.tab !== tab.id)];
}
