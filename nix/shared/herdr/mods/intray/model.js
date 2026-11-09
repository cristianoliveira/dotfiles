const STATUSES = new Set(["working", "idle", "done", "blocked"]);
const attention = status => status === "done" || status === "blocked";
const addressOK = address => typeof address === "string" && address.length > 0 && address.length <= 512;
const text = value => typeof value === "string" ? value.slice(0, 240) : "";

export function emptyState() {
  return { version: 1, serial: 0, seen: [], events: [] };
}

export function restoreState(raw) {
  try {
    const state = JSON.parse(raw);
    if (state?.version !== 1 || !Array.isArray(state.seen) || !Array.isArray(state.events)) return emptyState();
    const ids = new Set();
    const events = state.events.slice(0, 100).filter(event => {
      if (!Number.isSafeInteger(event?.id) || event.id <= 0 || ids.has(event.id) ||
          !addressOK(event.address) || !attention(event.status)) return false;
      ids.add(event.id);
      return true;
    })
      .map(event => ({ id: event.id, address: event.address, status: event.status,
        title: text(event.title), space: text(event.space), tab: text(event.tab) }));
    const seen = state.seen.slice(-1000).filter(pair =>
      Array.isArray(pair) && pair.length === 2 && addressOK(pair[0]) && STATUSES.has(pair[1]));
    const max = Math.max(0, ...events.map(event => event.id));
    const serial = Number.isSafeInteger(state.serial) && state.serial >= max ? state.serial : max;
    if (serial > Number.MAX_SAFE_INTEGER - 1000) return emptyState();
    return { version: 1, serial, seen, events };
  } catch {
    return emptyState();
  }
}

export function observeEvents(state, agents) {
  const seen = new Map(state.seen);
  const incoming = [];
  let changed = false;
  const current = agents.filter(agent => addressOK(agent?.address) && STATUSES.has(agent.status) &&
    Number.isSafeInteger(agent.seq) && agent.seq >= 0)
    .sort((a, b) => {
      if (a.seq !== b.seq) return b.seq - a.seq;
      if (a.address === b.address) return 0;
      return a.address < b.address ? -1 : 1;
    });
  const visited = new Set();
  for (const agent of current) {
    if (visited.has(agent.address)) continue;
    if (visited.size === 1000) break;
    visited.add(agent.address);
    if (seen.get(agent.address) === agent.status) continue;
    seen.delete(agent.address);
    seen.set(agent.address, agent.status);
    changed = true;
    if (attention(agent.status)) incoming.push(agent);
  }
  if (!changed) return state;
  // Evict absent terminals, never an unchanged terminal in the current snapshot.
  for (const address of seen.keys()) {
    if (seen.size <= 1000) break;
    if (!visited.has(address)) seen.delete(address);
  }

  const events = incoming.map((agent, index) => ({
    id: state.serial + index + 1, address: agent.address, status: agent.status,
    title: text(agent.title), space: text(agent.space_name), tab: text(agent.tab_name),
  }));
  return { version: 1, serial: state.serial + events.length,
    seen: [...seen], events: [...events, ...state.events].slice(0, 100) };
}

export function filterEvents(events, query, status = "all") {
  if (status !== "all") events = events.filter(event => event.status === status);
  const terms = query.trim().toLowerCase().split(/\s+/).filter(Boolean);
  if (!terms.length) return events;
  return events.filter(event => {
    const label = event.status === "blocked" ? "needs input" : "finished";
    const text = [event.title, event.space, event.tab, event.address, event.status, label].join(" ").toLowerCase();
    return terms.every(term => text.includes(term));
  });
}

export function dismissEvent(state, id) {
  return dismissEvents(state, [id]);
}

export function dismissEvents(state, ids) {
  const dismissed = new Set(ids);
  const events = state.events.filter(event => !dismissed.has(event.id));
  return events.length === state.events.length ? state : { ...state, events };
}

export function jumpCommand(event, terminals) {
  if (!event || !addressOK(event.address)) return null;
  if (!terminals.some(terminal => terminal.address === event.address && terminal.state === "live")) return null;
  return ["agent.focus", { terminal: event.address }];
}
