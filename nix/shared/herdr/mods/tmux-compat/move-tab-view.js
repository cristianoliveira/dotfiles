import { div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { spaces, run, theme, closeOverlay } from "herdr";
import { moveTabTo } from "./move-tab.js";

export class MoveTabMode {
  constructor(props, cx) {
    this.overlay = props.overlay;
    this.target = props.target;
    this.message = "0 = first tab · 1 = second tab · Enter moves · Esc cancels";
    this.handle = cx.focus_handle();
    this.input = InputState.new({ placeholder: "Position (starting at 0)" });
    this.input.on("submit", (_event, cx) => this.submit(cx));
    this.input.focus();
  }

  submit(cx) {
    const error = moveTabTo(spaces(), this.target, this.input.value(), run);
    if (!error) {
      closeOverlay(this.overlay);
      return;
    }

    this.message = error;
    this.input.focus();
    cx.notify();
  }

  render() {
    const t = theme();
    return v_flex().id("move-tab-position").track_focus(this.handle)
      .w_full().h(160).p(16).gap(10).bg(t.popover).text_color(t.foreground)
      .on_key_down((event, cx) => {
        if (event.key !== "escape") return;
        cx.stop_propagation();
        closeOverlay(this.overlay);
      })
      .child(h_flex().justify_between()
        .child(div().font_semibold().child("Move tab to position"))
        .child(div().id("move-tab-cancel").cursor_pointer().text_color(t.muted)
          .on_click(() => closeOverlay(this.overlay)).child("Cancel · Esc")))
      .child(Input.new(this.input).w_full().h(36).px(10).rounded(5)
        .bg(t.background).text_color(t.foreground))
      .child(div().text_size(12).text_color(t.muted).child(this.message));
  }
}
