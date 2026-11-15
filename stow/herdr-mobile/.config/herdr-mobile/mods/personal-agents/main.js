// Agents, ported from herdr-app's agents mod: by priority (Needs you, Done,
// Working, Idle) or grouped by space, pinned ones first, each parent with
// the sub-agents it started. Tap opens one, swipe right closes it, long press
// for its menu. Sets shared "agents.needs" for the tab's badge.
// As a header (props.header): the sort button; props.sortMenu: the sort sheet.

import { View, div, h_flex, v_flex, svg, image } from "herdr-ui";
import { agents, terminals, run, theme, shared, setShared, openOverlay, closeOverlay, props } from "herdr";

const RANK = { blocked: 4, done: 3, working: 2, idle: 1 };
const SECTION = { 4: "Needs attention", 3: "Done", 2: "Working", 1: "Idle" };
const DISPLAY_RANK = { 4: 3, 3: 2, 2: 4, 1: 1 };
const SECTION_STATUS = { 4: "blocked", 3: "done", 2: "working" };
const SORTS = [
  { id: "priority", label: "Priority", icon: "clock" },
  { id: "grouped", label: "Grouped by space", icon: "layers" },
];
const sortOf = () => SORTS.find((s) => s.id === shared("agents.sort")) ?? SORTS[0];

function duration(ms) {
  const m = Math.floor(ms / 60000);
  if (m < 1) return "<1m";
  if (m < 60) return `${m}m`;
  const h = Math.floor(m / 60);
  return h < 24 ? `${h}h` : `${Math.floor(h / 24)}d`;
}

function icon(p, size, color) {
  if (!p?.icon) return null;
  return p.tint ? svg(p.icon).size(size).text_color(color) : image(p.icon).size(size);
}

function mark(t, status, compact) {
  if (status === "working") return svg("icons/ui/spinner.svg").size(16).text_color(t.working).spin(900);
  if (status === "blocked" && compact) return div().px(6).rounded(5).bg(t.blocked + "26").text_size(12).font_bold().text_color(t.blocked).child("!");
  if (status === "blocked") return div().px(8).py(2).rounded(6).bg(t.blocked + "26").text_size(12).font_semibold().text_color(t.blocked).child("Needs you");
  if (status === "done") return div().size(9).rounded_full().bg(t.done);
  if (status === "idle") return div().size(9).rounded_full().border(1.5).border_color(t.idle);
  return div().size(9);
}

export default class Agents extends View {
  init(_props, cx) {
    if (props().header || props().sortMenu) return;
    this.folded = new Set();
    // When each agent's state last changed, kept across restarts.
    this.changed = JSON.parse(localStorage.getItem("changed") ?? "{}");
    cx.timer.every(30000, (cx) => cx.notify());
  }

  // Stamps agents whose state changed; done and idle count as one.
  track(list, now) {
    let dirty = false;
    for (const a of list) {
      const s = a.status === "done" ? "idle" : a.status;
      if (this.changed[a.address]?.s === s) continue;
      this.changed[a.address] = { s, at: a.statusAt ?? now };
      dirty = true;
    }
    if (dirty) localStorage.setItem("changed", JSON.stringify(this.changed));
  }

  // Live sub-agents of an agent, depth first.
  tree(all, addr, depth = 1) {
    return all.filter((k) => k.parent === addr && k.state === "live").flatMap((k) => [{ term: k, depth }, ...this.tree(all, k.address, depth + 1)]);
  }

  header(t) {
    const sort = sortOf();
    return div().id("sort").p(6)
      .on_click(() => openOverlay({ mod: "personal-agents", kind: "sheet", props: { sortMenu: true } }))
      .child(svg(`icons/ui/${sort.icon}.svg`).size(20).text_color(t.foreground));
  }

  sortMenu(t) {
    const on = sortOf().id;
    return v_flex().w_full().p(8).gap(2)
      .child(div().px(12).py(8).text_size(13).text_color(t.dim).child("Sort agents"))
      .children(SORTS.map((s) => h_flex().id(`sort-${s.id}`).h(52).px(12).gap(12).items_center().rounded(10)
        .on_click(() => {
          setShared("agents.sort", s.id);
          closeOverlay(props().overlay);
        })
        .child(svg(`icons/ui/${s.icon}.svg`).size(20).text_color(t.muted))
        .child(div().flex_1().text_size(16).text_color(t.foreground).child(s.label))
        .when(s.id === on, (el) => el.child(svg("icons/ui/check.svg").size(20).text_color(t.accent)))));
  }

  subRow(t, { term, depth }) {
    const st = term.status === "done" ? "idle" : term.status;
    return h_flex().id(`sub-${term.address}`).min_h(44).py(6).pr(16).pl(28 + depth * 20).gap(10).items_center()
      .on_click(() => run("terminal.show", { terminal: term.address }))
      .on_long_press(() => openOverlay({ mod: "menu", kind: "sheet", props: { target: "agent", terminal: term.address } }))
      .child(div().text_color(t.input).child("\u2514"))
      .child(icon(term.program, 16, t.foreground) ?? div())
      .child(div().flex_1().truncate().text_size(14).text_color(t.muted).child(term.name || term.program.name))
      .child(mark(t, st, true));
  }

  row(t, a, full, pinned, subs, now) {
    const when = this.changed[a.address]?.at;
    const repeats = !a.title || a.title === a.program.name || (a.message && a.title.includes(a.message));
    const label = full ? a.space_name || a.program.name : repeats ? a.program.name : a.title;
    // The title as a detail, unless it only repeats the program or the message (Pi's is "π - <message>").
    const detail = full && !repeats ? a.title : null;
    const open = !this.folded.has(a.address);
    return h_flex().id(`ag-${a.address}`).min_h(60).py(8).px(16).gap(12).items_center()
      .on_click(() => run("terminal.show", { terminal: a.address }))
      .on_long_press(() => openOverlay({ mod: "menu", kind: "sheet", props: { target: "agent", terminal: a.address, pinned } }))
      .swipe("right", { label: "Close", color: t.blocked, action: () => run("terminal.close", { terminal: a.address }) })
      .child(icon(a.program, 22, t.foreground) ?? div().size(22))
      .child(v_flex().flex_1().min_w(0)
        .child(h_flex().gap(6).items_center()
          .child(div().max_w(detail ? 150 : 400).truncate().text_size(16).text_color(a.status === "idle" ? t.muted : t.foreground).child(label))
          .when(Boolean(detail), (el) => el.child(div().flex_1().truncate().text_size(14).text_color(t.dim).child(`\u00b7 ${detail}`))))
        .when(Boolean(a.message), (el) => el.child(div().truncate().text_size(13).text_color(a.status === "blocked" ? t.blocked : t.muted).child(a.message))))
      .when(subs.length > 0, (el) => el.child(div().id(`fold-${a.address}`).px(6).py(4).rounded(6).bg(t.raised)
        .on_click((_e, cx) => {
          open ? this.folded.add(a.address) : this.folded.delete(a.address);
          cx.notify();
        })
        .child(div().text_size(12).text_color(t.muted).child(open ? "\u2212" : String(subs.length)))))
      .child(div().text_size(12).text_color(t.dim).child(a.machine))
      .when(Boolean(when), (el) => el.child(div().text_size(12).text_color(t.dim).child(duration(now - when))))
      .child(mark(t, a.status, full && !pinned));
  }

  render(cx) {
    const t = theme();
    if (props().header) return this.header(t);
    if (props().sortMenu) return this.sortMenu(t);
    const now = Date.now();
    const all = terminals();
    const sub = new Set(all.filter((k) => k.parent).map((k) => k.address));
    // Agents others started show under their parent, not on their own.
    let list = agents().filter((a) => !sub.has(a.address) || !all.some((k) => k.address === a.parent && k.state === "live"));
    this.track(agents(), now);
    const needs = agents().filter((a) => a.status === "blocked" || a.status === "done").length;
    if (shared("agents.needs") !== needs) setShared("agents.needs", needs);

    const sort = sortOf();
    const byPriority = sort.id === "priority";
    const rankOf = (a) => Math.max(RANK[a.status] ?? 0, ...this.tree(all, a.address).map((s) => RANK[s.term.status === "done" ? "idle" : s.term.status] ?? 0));
    const since = (a) => this.changed[a.address]?.at ?? 0;
    if (byPriority) list = [...list].sort((x, y) => DISPLAY_RANK[rankOf(y)] - DISPLAY_RANK[rankOf(x)] || since(y) - since(x));
    const pins = shared("agents.pins") ?? [];
    const pinned = pins.map((p) => list.find((a) => a.address === p)).filter(Boolean);
    const rest = list.filter((a) => !pins.includes(a.address));

    const groups = pinned.length ? [{ id: "pinned", label: "Pinned", status: null, members: pinned }] : [];
    for (const a of rest) {
      const r = rankOf(a) || RANK.idle;
      const id = byPriority ? `sec-${r}` : `sp-${a.space}`;
      if (groups.at(-1)?.id === id) groups.at(-1).members.push(a);
      else groups.push({ id, label: byPriority ? SECTION[r] : a.space_name || "No space", status: byPriority ? SECTION_STATUS[r] : null, members: [a] });
    }

    const rows = groups.flatMap((g) => {
      const open = !this.folded.has(g.id);
      const head = h_flex().id(g.id).h(40).px(16).pt(8).gap(8).items_center()
        .on_click((_e, cx) => {
          open ? this.folded.add(g.id) : this.folded.delete(g.id);
          cx.notify();
        })
        .child(div().text_size(13).font_semibold().text_color(t[g.status] ?? t.dim).child(g.label))
        .child(div().text_size(13).text_color(t.dim).child(String(g.members.length)))
        .child(div().flex_1())
        .child(svg(`icons/ui/chevron-${open ? "down" : "right"}.svg`).size(16).text_color(t.dim));
      if (!open) return [head];
      return [head, ...g.members.flatMap((a) => {
        const subs = this.tree(all, a.address);
        const isPinned = pins.includes(a.address);
        const r = this.row(t, a, byPriority || isPinned, isPinned, subs, now);
        return this.folded.has(a.address) ? [r] : [r, ...subs.map((s) => this.subRow(t, s))];
      })];
    });

    return v_flex().size_full().bg(t.background).overflow_y_scroll().pb(24)
      .when(list.length === 0, (el) => el.child(div().p(24).text_size(14).text_color(t.muted)
        .child("No agent status yet. Agents show up here when they report their status: Pi, Claude Code and others do in herdr-core.")))
      .children(rows);
  }
}
