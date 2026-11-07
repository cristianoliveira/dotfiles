export function sortRecentGroups(groups, history) {
  const key = (space, tab) => JSON.stringify([space, tab]);
  const ranks = new Map(history.map((visit, index) => [key(visit.space, visit.tab), index]));
  const rank = (space, tab) => ranks.get(key(space, tab)) ?? history.length;
  const sorted = groups.map(group => ({
    ...group,
    ctxs: [...group.ctxs].sort((a, b) => rank(group.w.id, a.ctx.id) - rank(group.w.id, b.ctx.id)),
  }));
  const first = group => group.ctxs.length ? rank(group.w.id, group.ctxs[0].ctx.id) : history.length;
  return sorted.sort((a, b) => first(a) - first(b));
}
