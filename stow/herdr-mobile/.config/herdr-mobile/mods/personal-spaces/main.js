// Spaces by machine, ported from herdr-app's spaces mod: a color avatar per
// space, where its first terminal is now (repo, branch, ahead/behind), and
// worktree spaces under their repo's. Tap opens the space; long press opens
// its menu. The screen menu keeps search and new-space actions within reach.

import { View, div, h_flex, v_flex, svg } from "herdr-ui";
import { spaces, machines, terminals, run, openOverlay, exec, theme, shared, setShared, props } from "herdr";

// One strong color per hue, the same in every mod that draws space avatars.
const MARK = { ansi6: "#22a99a", ansi3: "#e3814f", ansi4: "#5b8def", ansi5: "#8b7cf6", ansi2: "#3fae6a", ansi1: "#d9649a" };
const PALETTE = ["ansi6", "ansi3", "ansi4", "ansi5", "ansi2", "ansi1"];

// A space color for each space, kept in shared "space.colors": the theme
// color fewest spaces use, given once, so adding spaces moves nothing.
function colors() {
  const sp = spaces();
  const ids = new Set(sp.map((s) => s.id));
  const saved = shared("space.colors") ?? {};
  const kept = Object.fromEntries(Object.entries(saved).filter(([id]) => ids.has(id)));
  let changed = Object.keys(kept).length !== Object.keys(saved).length;
  for (const s of sp) {
    if (kept[s.id] || s.name === "~") continue;
    const uses = (c) => Object.values(kept).filter((v) => v === c).length;
    kept[s.id] = PALETTE.reduce((best, c) => (uses(c) < uses(best) ? c : best));
    changed = true;
  }
  if (changed) setShared("space.colors", kept);
  return kept;
}

// Where a space is now: its first terminal's live folder, else where it was made.
function place(s, terms) {
  const first = s.tabs.flatMap((t) => t.terminals)[0];
  return terms.find((t) => t.address === first)?.cwd || s.folder;
}

const base = (p) => p.replace(/\/+$/, "").split("/").pop();

// One git look per place, in one command: branch, ahead/behind, repo.
const GIT = 'git --no-optional-locks status --porcelain=v2 --branch 2>/dev/null || exit 1; echo "@@"; git rev-parse --show-toplevel; git rev-parse --path-format=absolute --git-common-dir';

function parseGit(out) {
  const [status, rest = ""] = out.split("@@\n");
  const [top, common] = rest.trim().split("\n");
  const info = { branch: null, ahead: 0, behind: 0 };
  for (const line of status.split("\n")) {
    if (line.startsWith("# branch.head ")) info.branch = line.slice(14);
    else if (line.startsWith("# branch.ab ")) {
      const [a, b] = line.slice(12).split(" ");
      info.ahead = Math.abs(parseInt(a, 10)) || 0;
      info.behind = Math.abs(parseInt(b, 10)) || 0;
    }
  }
  const repo = common?.endsWith("/.git") ? common.slice(0, -5) : common ?? "";
  return { ...info, repo, name: base(repo), linked: !!top && repo !== top };
}

export default class Spaces extends View {
  init(_props, cx) {
    if (props().header) return;
    this.menuOpen = false;
    this.git = {}; // machine + place → git info, null: not a repo
    this.turns = {}; // terminal → its turn when last seen
    this.folded = new Set(JSON.parse(localStorage.getItem("machines.folded") ?? "[]"));
    this.refresh(cx);
  }

  key(s, terms) {
    return `${s.machine}\u0000${place(s, terms)}`;
  }

  // Looks at git where it could have changed: new places, and spaces whose
  // agent just finished a turn (a commit, a checkout).
  due(terms) {
    const due = new Set();
    for (const s of spaces()) {
      const k = this.key(s, terms);
      if (k in this.git) continue;
      this.git[k] = null; // looking
      due.add(s.id);
    }
    for (const t of terms) {
      if (t.space && this.turns[t.address] !== undefined && this.turns[t.address] !== t.turn) due.add(t.space);
      this.turns[t.address] = t.turn;
    }
    return due;
  }

  refresh(cx, only) {
    if (this.busy) {
      this.again = true;
      return;
    }
    this.busy = true;
    cx.spawn(async (cx) => {
      const terms = terminals();
      for (const s of spaces()) {
        if (only && !only.has(s.id)) continue;
        const k = this.key(s, terms);
        try {
          const r = await exec("sh", ["-c", GIT], { cwd: place(s, terms), on: s.machine });
          this.git[k] = r.code === 0 ? parseGit(r.stdout) : null;
        } catch {
          this.git[k] ??= null;
        }
      }
      this.busy = false;
      cx.notify();
      if (this.again) {
        this.again = false;
        this.refresh(cx);
      }
    });
  }

  header(t) {
    return h_flex().gap(4).items_center();
  }

  // Spaces in order, each worktree space under its main checkout's.
  ordered(list, terms) {
    const rows = list.map((s) => ({ s, g: this.git[this.key(s, terms)] ?? null }));
    const mains = new Set(rows.filter((r) => r.g && !r.g.linked).map((r) => r.g.repo));
    const nested = (r) => r.g?.linked && mains.has(r.g.repo);
    const out = [];
    for (const r of rows) {
      if (nested(r)) continue;
      out.push({ ...r, tree: false });
      if (r.g && !r.g.linked) for (const k of rows.filter((x) => nested(x) && x.g.repo === r.g.repo)) out.push({ ...k, tree: true });
    }
    return out;
  }

  // Only what's unusual after the name: the repo when the name doesn't say it,
  // a branch other than main/master, ahead and behind.
  tail(g, tree, name, t) {
    const same = (a) => a.toLowerCase() === name.toLowerCase();
    const raw = g.branch ?? "detached";
    const branch = same(raw) || raw === "master" || raw === "main" ? "" : raw;
    const repo = tree || same(g.name) ? "" : g.name;
    const where = [repo, branch].filter(Boolean).join(" \u00b7 ");
    return h_flex().flex_1().min_w(0).gap(6).justify_end().items_center().text_size(13).text_color(t.dim)
      .when(Boolean(where), (el) => el.child(div().flex_shrink().truncate().child(where)))
      .when(g.ahead > 0, (el) => el.child(div().text_color(t.ansi2).child(`\u2191${g.ahead}`)))
      .when(g.behind > 0, (el) => el.child(div().text_color(t.ansi1).child(`\u2193${g.behind}`)));
  }

  row({ s, g, tree }, t, color) {
    const fill = color?.startsWith("#") ? color : MARK[color] ?? t.dim;
    const needs = s.status === "blocked" || s.status === "done";
    return h_flex().id(`space-${s.id}`).h(52).px(16).gap(12).items_center()
      .on_click(() => run("screen.open", { mod: "space", props: { space: s.id }, title: s.name }))
      .on_long_press(() => openOverlay({ mod: "menu", kind: "sheet", props: { target: "space", id: s.id } }))
      .when(tree, (el) => el.pl(28).child(svg("icons/ui/branch.svg").size(16).text_color(t.dim)))
      .when(!tree, (el) => el.child(h_flex().size(28).rounded(7).bg(fill).items_center().justify_center()
        .child(div().text_size(14).font_bold().text_color("#ffffff").child(s.name[0]?.toUpperCase() ?? "?"))))
      .child(div().flex_shrink().max_w(220).truncate().text_size(16).text_color(t.foreground).child(s.name))
      .child(g ? this.tail(g, tree, s.name, t) : div().flex_1())
      .when(needs, (el) => el.child(div().size(9).rounded_full().bg(t[s.status])));
  }

  render(cx) {
    const t = theme();
    if (props().header) return this.header(t);
    const terms = terminals();
    const due = this.due(terms);
    if (due.size) cx.timer.after(300, (cx) => this.refresh(cx, due));
    const color = colors();
    const sp = spaces();
    const names = [...new Set([...machines().map((m) => m.name), ...sp.map((s) => s.machine)])];
    const groups = names.flatMap((m) => {
      const machine = machines().find((x) => x.name === m);
      const connected = machine?.state === "connected";
      const folded = this.folded.has(m);
      const mine = sp.filter((s) => s.machine === m);
      const head = h_flex().id(`machine-${m}`).h(44).px(16).gap(10).items_center()
        .on_click((_e, cx) => {
          folded ? this.folded.delete(m) : this.folded.add(m);
          localStorage.setItem("machines.folded", JSON.stringify([...this.folded]));
          cx.notify();
        })
        .child(svg("icons/ui/server.svg").size(16).text_color(t.dim))
        .child(div().flex_1().truncate().text_size(13).font_semibold().text_color(t.muted).child(m))
        .when(!connected, (el) => el.child(div().text_size(12).text_color(t.dim).child(machine?.state ?? "offline")))
        .when(connected, (el) => el.child(div().id(`machine-new-${m}`).p(6)
          .on_click(() => openOverlay({ mod: "new-menu", kind: "sheet", props: { machine: m } }))
          .child(svg("icons/ui/plus.svg").size(18).text_color(t.muted))))
        .child(div().size(7).rounded_full().bg(connected ? t.ansi2 : t.dim))
        .child(svg(`icons/ui/chevron-${folded ? "right" : "down"}.svg`).size(16).text_color(t.dim));
      if (folded) return [head];
      const rows = mine.length
        ? this.ordered(mine, terms).map((r) => this.row(r, t, color[r.s.id]))
        : [div().px(16).py(10).text_size(14).text_color(t.dim).child(connected ? "No spaces. Tap + to start one." : "Not connected.")];
      return [head, ...rows];
    });
    const list = v_flex().flex_1().bg(t.background).overflow_y_scroll().pb(96)
      .on_refresh((_e, cx) => this.refresh(cx))
      .children(groups)
      .when(names.length === 0, (el) => el.child(div().p(24).text_color(t.muted).child("Add a machine in Settings to see its spaces.")));
    const action = (id, icon, right, bottom, color, open) =>
      h_flex().id(id).absolute().right(right).bottom(bottom).size(48)
        .rounded_full().bg(color).items_center().justify_center()
        .on_click((_e, cx) => {
          this.menuOpen = false;
          cx.notify();
          open();
        })
        .child(svg(`icons/ui/${icon}.svg`).size(24).text_color("#ffffff"));
    const launcher = h_flex().id("spaces-menu-launcher").absolute().right(20).bottom(16)
      .size(56).rounded_full().bg(t.ansi4).items_center().justify_center()
      .on_click((_e, cx) => {
        this.menuOpen = !this.menuOpen;
        cx.notify();
      })
      .child(svg(`icons/ui/${this.menuOpen ? "x" : "plus"}.svg`).size(24).text_color("#ffffff"));
    return v_flex().size_full().relative().bg(t.background)
      .child(list)
      .when(this.menuOpen, (el) => el
        .child(action("spaces-menu-search", "search", 24, 80, t.ansi4,
          () => openOverlay({ mod: "picker", kind: "sheet" })))
        .child(action("spaces-menu-add", "plus", 84, 20, t.ansi3,
          () => openOverlay({ mod: "new-menu", kind: "sheet", props: {} }))))
      .child(launcher);
  }
}
