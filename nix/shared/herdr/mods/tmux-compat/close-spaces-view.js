import { div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, v_virtual_list, VirtualListScrollHandle } from "gpui-base";
import { spaces, run, theme, closeOverlay } from "herdr";
import { SpaceCloser, filterSpaces } from "./close-spaces.js";

export class CloseSpacesMode {
  constructor(props, cx) {
    this.overlay = props.overlay;
    this.model = new SpaceCloser();
    this.query = "";
    this.at = 0;
    this.message = "Closing a space ends ALL its terminals, including remote terminals.";
    this.handle = cx.focus_handle();
    this.scroll = VirtualListScrollHandle.new();
    this.input = InputState.new({ placeholder: "Filter spaces by name, machine or folder…" });
    this.input.on("change", (_event, cx) => {
      this.query = this.input.value();
      this.at = 0;
      this.scroll.scroll_to_item(0);
      cx.notify();
    });
    this.input.on("submit", (_event, cx) => this.review(cx));
    this.input.focus();
  }

  dismiss() {
    this.model.cancel();
    closeOverlay(this.overlay);
  }

  review(cx) {
    if (!this.model.beginReview(spaces())) {
      this.message = "Select one or more spaces first.";
    } else {
      this.scroll.scroll_to_item(0);
      this.handle.focus();
    }
    cx.notify();
  }

  confirm(cx) {
    const result = this.model.confirm(spaces());
    if (result.status === "changed") {
      this.message = "Spaces changed while reviewing. Nothing was closed; review again.";
      this.input.focus();
      cx.notify();
      return;
    }
    if (result.status !== "ready") return;

    for (const command of result.commands) run(...command);
    closeOverlay(this.overlay);
  }

  back(cx) {
    this.model.back();
    this.input.focus();
    cx.notify();
  }

  button(id, label, action, danger = false) {
    const t = theme();
    return div().id(id).px(12).py(8).rounded(5).cursor_pointer()
      .bg(danger ? t.ansi1 : t.hover).text_color(danger ? "#ffffff" : t.foreground)
      .on_click((_event, cx) => action(cx)).child(label);
  }

  render() {
    const t = theme();
    const reviewing = this.model.review !== null;
    const rows = reviewing ? this.model.review : filterSpaces(spaces(), this.query);
    this.at = Math.max(0, Math.min(this.at, rows.length - 1));

    return v_flex().id("tmux-close-spaces").track_focus(this.handle)
      .w_full().h(480).p(16).gap(10).bg(t.popover).text_size(13)
      .on_key_down((event, cx) => {
        if (event.key === "escape") this.dismiss();
        else if (reviewing && event.keystroke === "ctrl-enter") this.confirm(cx);
        else if (!reviewing && (event.key === "down" || event.key === "up")) {
          const step = event.key === "down" ? 1 : -1;
          this.at = rows.length ? (this.at + step + rows.length) % rows.length : 0;
          this.scroll.scroll_to_item(this.at, "center");
        } else if (!reviewing && (event.key === "tab" || event.keystroke === "ctrl-space")) {
          this.model.toggle(rows[this.at]?.id, spaces());
          this.at = rows.length ? (this.at + 1) % rows.length : 0;
          this.scroll.scroll_to_item(this.at, "center");
        } else return;
        cx.stop_propagation();
        cx.notify();
      })
      .child(div().font_semibold().text_color(reviewing ? t.ansi1 : t.foreground)
        .child(reviewing ? `Close ${rows.length} spaces and terminate their terminals?` : "Select spaces to close"))
      .child(reviewing
        ? div().text_color(t.muted).child("Includes remote terminals. Review every machine and space below.")
        : Input.new(this.input).w_full().h(36).px(10).rounded(5)
          .bg(t.background).text_color(t.foreground))
      .child(div().text_size(12).text_color(t.muted).child(reviewing
        ? "This cannot be undone. Press Ctrl+Enter or click Close spaces to confirm."
        : this.message))
      .child(rows.length
        ? v_virtual_list("close-space-list", rows.length, 40, (index) => rows[index].id,
          (range) => rows.slice(range.start, range.end).map((space, offset) =>
            h_flex().h(40).px(8).gap(8).items_center().rounded(5)
              .bg(!reviewing && range.start + offset === this.at ? t.hover : t.popover)
              .child(div().text_color(t.accent).child(reviewing || this.model.selected.has(space.id) ? "[x]" : "[ ]"))
              .child(div().flex_1().truncate().text_color(t.foreground).child(space.name))
              .child(div().text_size(12).text_color(t.muted)
                .child(`${space.machine ?? "local"} · ${space.tabs.length} tabs${space.active ? " · current" : ""}`))))
          .h(280).w_full().track_scroll(this.scroll)
          .on_item_click((id, cx) => {
            this.model.toggle(id, spaces());
            cx.notify();
          })
        : div().h(280).text_color(t.muted).child("No spaces match."))
      .child(h_flex().gap(8).items_center().justify_between()
        .child(this.button("close-cancel", "Cancel · Esc", () => this.dismiss()))
        .child(reviewing
          ? h_flex().gap(8)
            .child(this.button("close-back", "Back", (cx) => this.back(cx)))
            .child(this.button("close-confirm", "Close spaces · Ctrl+Enter", (cx) => this.confirm(cx), true))
          : this.button("close-review", `Review ${this.model.selected.size} selected`, (cx) => this.review(cx))))
      .when(!reviewing, (element) => element.child(div().text_size(11).text_color(t.dim)
        .child("↑/↓ navigate · Tab/Ctrl+Space or click selects · Enter reviews")));
  }

  close() {
    this.model.cancel();
  }
}
