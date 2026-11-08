import { View, div } from "gpui-kit";
import { v_flex, h_flex, v_virtual_list, VirtualListScrollHandle, InputState, Input } from "gpui-base";
import { agents, terminals, run, theme, props, closeOverlay, shared, setShared, notify } from "herdr";
import { restoreState, observeEvents, dismissEvent, jumpCommand, filterEvents } from "./model.js";

export default class Intray extends View {
  init(_props, cx) {
    this.observer = props()?.mode === "observer";
    this.overlay = props()?.overlay;
    this.selected = null;
    if (this.observer) return;
    this.handle = cx.focus_handle();
    this.scroll = VirtualListScrollHandle.new();
    this.filter = "";
    this.input = InputState.new({ placeholder: "Search notifications…" });
    this.input.on("change", (_event, cx) => {
      this.filter = this.input.value();
      this.selected = null;
      this.scroll.scroll_to_item(0, "center");
      cx.notify();
    });
    this.input.on("submit", () => {
      const rows = filterEvents(this.observe(), this.filter);
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

  choose(event) {
    if (!event) return;
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
    const rows = filterEvents(events, this.filter);
    const t = theme();
    const at = Math.max(0, rows.findIndex(event => event.id === this.selected));
    const live = new Set(terminals().filter(terminal => terminal.state === "live").map(terminal => terminal.address));
    return v_flex().id("intray").track_focus(this.handle)
      .w_full().h(486).p(16).gap(10).bg(t.popover).text_size(13)
      .on_key_down((event, cx) => {
        if (event.key === "escape") closeOverlay(this.overlay);
        else if (event.keystroke === "ctrl-d" && rows[at]) {
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
      .child(h_flex().justify_between().items_center()
        .child(div().font_semibold().text_color(t.foreground).child("Intray"))
        .child(div().text_color(t.dim).child("Newest unread first")))
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
          ? "No matching notifications. Clear search to show all unread events."
          : "No unread events. Finished agents and requests for input appear here."))
      .child(div().text_size(11).text_color(t.dim)
        .child(`${rows.length} of ${events.length} unread · ↑/↓ or Ctrl-j/k select · Enter jump & read · Ctrl-d dismiss · Esc close`));
  }
}
