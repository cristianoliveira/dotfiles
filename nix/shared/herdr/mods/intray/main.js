import { View, div } from "gpui-kit";
import { v_flex, h_flex, v_virtual_list, VirtualListScrollHandle, InputState, Input, Tabs, Tab, Button } from "gpui-base";
import { agents, terminals, run, theme, props, closeOverlay, shared, setShared, notify } from "herdr";
import { restoreState, observeEvents, dismissEvent, dismissEvents, jumpCommand, filterEvents } from "./model.js";

const STATUS_TABS = [["all", "All"], ["done", "Finished"], ["blocked", "Needs input"]];

export default class Intray extends View {
  init(_props, cx) {
    this.observer = props()?.mode === "observer";
    this.overlay = props()?.overlay;
    this.selected = null;
    if (this.observer) return;
    this.handle = cx.focus_handle();
    this.scroll = VirtualListScrollHandle.new();
    this.filter = "";
    this.statusFilter = "all";
    this.pendingDismissal = null;
    this.input = InputState.new({ placeholder: "Search notifications…" });
    this.input.on("change", (_event, cx) => {
      this.filter = this.input.value();
      this.selected = null;
      this.scroll.scroll_to_item(0, "center");
      cx.notify();
    });
    this.input.on("submit", () => {
      if (this.pendingDismissal) return;
      const rows = filterEvents(this.observe(), this.filter, this.statusFilter);
      this.choose(rows.find(event => event.id === this.selected) ?? rows[0]);
    });
    this.input.focus();
  }

  observe() {
    // Herdr's shared store is persisted and common to the observer and popup.
    const raw = shared("intray.state");
    const state = observeEvents(restoreState(raw), agents());
    const encoded = JSON.stringify(state);
    if (encoded !== raw) setShared("intray.state", encoded);
    return state.events;
  }

  selectStatus(status) {
    this.statusFilter = status;
    this.selected = null;
    this.scroll.scroll_to_item(0, "center");
    this.input.focus();
  }

  requestDismissAll(events) {
    if (!events.length || this.pendingDismissal) return;
    this.pendingDismissal = events.map(event => event.id);
    this.input.focus();
  }

  cancelDismissAll() {
    this.pendingDismissal = null;
    this.input.focus();
  }

  confirmDismissAll() {
    if (!this.pendingDismissal) return;
    const state = restoreState(shared("intray.state"));
    const next = dismissEvents(state, this.pendingDismissal);
    if (next !== state) setShared("intray.state", JSON.stringify(next));
    this.cancelDismissAll();
    this.selected = null;
    this.scroll.scroll_to_item(0, "center");
  }

  button(id, label, action, disabled = false) {
    const t = theme();
    return Button.new(id).px(10).py(4).rounded(5).bg(t.hover)
      .text_color(disabled ? t.dim : t.foreground).disabled(disabled).cursor_pointer()
      .child(label).on_click((_event, cx) => { action(); cx.notify(); });
  }

  choose(event) {
    if (!event || this.pendingDismissal) return;
    const command = jumpCommand(event, terminals());
    if (!command) {
      notify({ title: "Terminal unavailable", body: "That event's terminal is no longer running.", level: "info" });
      return;
    }
    try {
      run(...command);
    } catch (error) {
      notify({ title: "Could not jump", body: error.message, level: "error" });
      return;
    }
    const state = dismissEvent(restoreState(shared("intray.state")), event.id);
    setShared("intray.state", JSON.stringify(state));
    closeOverlay(this.overlay);
  }

  render() {
    const events = this.observe();
    if (this.observer) return div().h(1);
    const category = filterEvents(events, "", this.statusFilter);
    const rows = filterEvents(category, this.filter);
    const pendingCount = this.pendingDismissal
      ? events.filter(event => this.pendingDismissal.includes(event.id)).length : 0;
    const t = theme();
    const at = Math.max(0, rows.findIndex(event => event.id === this.selected));
    const live = new Set(terminals().filter(terminal => terminal.state === "live").map(terminal => terminal.address));
    return v_flex().id("intray").track_focus(this.handle)
      .w_full().h(536).p(16).gap(10).bg(t.popover).text_size(13)
      .on_key_down((event, cx) => {
        const direct = ["ctrl-1", "ctrl-2", "ctrl-3"].indexOf(event.keystroke);
        if (event.key === "escape") {
          if (this.pendingDismissal) this.cancelDismissAll();
          else closeOverlay(this.overlay);
        }
        else if (event.keystroke === "ctrl-shift-d") this.requestDismissAll(this.observe());
        else if (event.keystroke === "ctrl-enter") this.confirmDismissAll();
        else if (direct !== -1) this.selectStatus(STATUS_TABS[direct][0]);
        else if (["tab", "shift-tab", "ctrl-h", "ctrl-l"].includes(event.keystroke)) {
          const index = STATUS_TABS.findIndex(([status]) => status === this.statusFilter);
          const step = ["tab", "ctrl-l"].includes(event.keystroke) ? 1 : -1;
          this.selectStatus(STATUS_TABS[(index + step + STATUS_TABS.length) % STATUS_TABS.length][0]);
        }
        else if (event.keystroke === "ctrl-d" && !this.pendingDismissal && rows[at]) {
          const state = dismissEvent(restoreState(shared("intray.state")), rows[at].id);
          setShared("intray.state", JSON.stringify(state));
          this.selected = null;
        }
        else if (["down", "up", "ctrl-j", "ctrl-k"].includes(event.keystroke)) {
          const step = ["down", "ctrl-j"].includes(event.keystroke) ? 1 : -1;
          const next = rows.length ? (at + step + rows.length) % rows.length : 0;
          this.selected = rows[next]?.id ?? null;
          this.scroll.scroll_to_item(next, "center");
        } else return;
        cx.stop_propagation();
        cx.notify();
      })
      .child(h_flex().h(28).flex_none().justify_between().items_center().gap(10)
        .child(div().text_color(t.foreground).text_size(this.pendingDismissal ? 12 : 13)
          .child(this.pendingDismissal ? `Dismiss ${pendingCount} unread across all statuses/search?` : "Intray"))
        .child(this.pendingDismissal
          ? h_flex().gap(6)
            .child(this.button("dismiss-cancel", "Cancel", () => this.cancelDismissAll()))
            .child(this.button("dismiss-confirm", "Confirm · Ctrl+Enter", () => this.confirmDismissAll(), pendingCount === 0))
          : h_flex().items_center().gap(6)
            .child(div().text_size(11).text_color(t.dim).child("Ctrl+Shift+D"))
            .child(this.button("dismiss-all", "Dismiss all", () => this.requestDismissAll(this.observe()), events.length === 0))))
      .child(h_flex().h(28).flex_none().items_center().gap(10)
        .child(Tabs.new("intray-status").flex().flex_row().flex_1().gap(6)
          .children(STATUS_TABS.map(([status, label]) => {
            const active = status === this.statusFilter;
            const count = filterEvents(events, "", status).length;
            return Tab.new(`intray-status-${status}`).selected(active).px(10).py(5).rounded(5)
              .bg(active ? t.hover : t.popover).text_color(active ? t.accent : t.dim).cursor_pointer()
              .child(`${label} (${count})`)
              .on_click((_event, cx) => { this.selectStatus(status); cx.notify(); });
          })))
        .child(div().text_size(11).text_color(t.dim).child("Tab / Shift-Tab · Ctrl-h/l · Ctrl-1/2/3")))
      .child(h_flex().h(36).flex_none().px(10).items_center().rounded(5)
        .border_1().border_color(t.accent).bg(t.background)
        .child(Input.new(this.input).flex_1().h_full().text_size(13).text_color(t.foreground)))
      .child(rows.length
        ? v_virtual_list("intray-events", rows.length, 52, index => String(rows[index].id),
          range => rows.slice(range.start, range.end).map((event, offset) =>
            v_flex().h(52).px(10).py(5).gap(3).rounded(5)
              .bg(range.start + offset === at ? t.hover : t.popover)
              .child(h_flex().gap(10).items_center()
                .child(div().text_color(event.status === "blocked" ? t.blocked : t.done)
                  .child(event.status === "blocked" ? "Needs input" : "Finished"))
                .child(div().flex_1().truncate().text_color(t.foreground).child(event.title || event.tab || event.address)))
              .child(div().truncate().text_size(11).text_color(t.dim)
                .child([event.space, event.tab, live.has(event.address) ? event.address : "unavailable"].filter(Boolean).join(" · ")))))
          .h(340).w_full().track_scroll(this.scroll)
          .on_item_click(id => this.choose(rows.find(event => String(event.id) === id)))
        : div().flex_1().text_color(t.muted).child(events.length
          ? "No matching notifications. Clear search or choose another status."
          : "No unread events. Finished agents and requests for input appear here."))
      .child(div().text_size(11).text_color(t.dim)
        .child(this.pendingDismissal
          ? "Ctrl+Enter confirm · Esc cancel · New arrivals stay unread"
          : `${rows.length} of ${category.length} unread · ↑/↓ or Ctrl-j/k select · Enter jump & read · Ctrl-d dismiss · Esc close`));
  }
}
