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
