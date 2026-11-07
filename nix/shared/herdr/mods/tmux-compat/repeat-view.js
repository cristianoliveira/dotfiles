import { div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { run, theme, closeOverlay } from "herdr";
import { RepeatSession, REPEAT_TIMEOUT_MS } from "./repeat.js";

export class RepeatMode {
  constructor(props, cx) {
    this.handle = cx.focus_handle();
    this.session = new RepeatSession(() => closeOverlay(props.overlay));
    this.session.arm(this.schedule(cx));
    this.handle.focus();
  }

  schedule(cx) {
    return (ms, callback) => {
      const timer = cx.timer.after(ms, callback);
      return () => timer.cancel();
    };
  }

  render() {
    const t = theme();
    return v_flex().id("tmux-repeat").track_focus(this.handle)
      .w_full().h(108).p(14).gap(8).bg(t.popover)
      .on_key_down((event, cx) => {
        cx.stop_propagation();
        const action = this.session.press(event.keystroke, this.schedule(cx));
        if (!action) return;
        run(...action);
        cx.timer.after(0, () => {
          if (this.session.active) this.handle.focus();
        });
      })
      .child(h_flex().justify_between()
        .child(div().text_color(t.accent).font_semibold().child("Repeat navigation"))
        .child(div().id("repeat-exit").text_color(t.muted).cursor_pointer()
          .on_click(() => this.session.finish()).child("Exit · Esc")))
      .child(div().text_color(t.foreground).child("n previous tab · p next tab · h/j/k/l panes"))
      .child(div().text_size(11).text_color(t.dim)
        .child(`Exits after ${REPEAT_TIMEOUT_MS / 1000}s idle. Other keys exit; press again to type.`));
  }

  close() {
    this.session.dispose();
  }
}
