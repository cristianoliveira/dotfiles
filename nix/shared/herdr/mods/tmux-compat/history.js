export function observeSpaces(history, spaces) {
  const live = new Set(spaces.map((space) => space.id));
  const previous = history.filter((id) => live.has(id));
  const current = spaces.find((space) => space.active)?.id;
  if (!current) return previous;

  return [current, ...previous.filter((id) => id !== current)].slice(0, 2);
}

export function lastSpace(history) {
  return history[1] ?? null;
}
