import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { spaces, agents, theme, props } from "herdr";
import { formatStatusTime } from "./clock.js";

export default class TmuxStatus extends View {
  init(_props, cx) {
    this.clockOnly = props()?.mode === "clock";
    if (!this.clockOnly) return;
    this.clock = formatStatusTime(new Date());
    cx.timer.every(1000, (cx) => {
      const clock = formatStatusTime(new Date());
      if (clock === this.clock) return;
      this.clock = clock;
      cx.notify();
    });
  }

  render() {
    const t = theme();
    if (this.clockOnly) return h_flex().size_full().px(10).items_center().justify_end()
      .bg(t.chrome).border_t(1).border_color(t.border)
      .text_size(11.8).text_color(t.muted).child(this.clock);
    const space = spaces().find(s => s.active);
    const list = agents();
    const needs = list.filter(a => a.status === "blocked").length;
    const label = (icon, text) => h_flex().gap(6).items_center()
      .child(svg(`mods/workspace-chrome/${icon}.svg`).size(13)).child(text);

    return h_flex().size_full().px(10).gap(12).items_center()
      .bg(t.chrome).border_t(1).border_color(t.border)
      .text_size(11.8).text_color(t.muted)
      .child(label(space?.machine ? "server" : "monitor", space?.machine ?? "This computer"))
      .child(h_flex().gap(6).items_center().child(`${list.length} agents`)
        .when(needs > 0, el => el.child(div().text_color(t.blocked).child(`· ${needs} needs you`))));
  }
}
