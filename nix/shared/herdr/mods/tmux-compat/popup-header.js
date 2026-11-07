import { div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { theme, closeOverlay, hc } from "herdr";
import { releasePopup } from "./popup.js";

export class PopupHeader {
  constructor(props) {
    this.hidden = props.hidden;
    this.overlay = props.overlay;
    this.address = props.address;
    this.script = props.script;
    this.shortcut = props.shortcut ?? "Ctrl+A Space";
    this.released = false;
  }

  render() {
    if (this.hidden) return div().h(1);
    const t = theme();
    return h_flex().id("tmux-popup-header").w_full().h(36).px(12).gap(12)
      .items_center().justify_between().bg(t.popover).text_size(12)
      .child(div().flex_1().truncate().text_color(t.foreground).child(this.script))
      .child(div().id("tmux-popup-close").cursor_pointer().text_color(t.accent)
        .on_click(() => closeOverlay(this.overlay)).child(`Close · ${this.shortcut}`));
  }

  async close() {
    if (this.released) return;
    this.released = true;
    await releasePopup(this.address, hc);
  }
}
