import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { spaces, exec, notify, theme, props, home } from "herdr";
import { ProjectWatchers } from "./projects.js";
import { watcherBinary } from "./model.js";

export default class FunzzyStatus extends View {
  init(_props, cx) {
    const binary = watcherBinary(props()?.binary, home());
    this.watchers = new ProjectWatchers({ spaces, exec, notify, binary });
    const poll = (cx) => cx.spawn(async (cx) => {
      await this.watchers.poll();
      cx.notify();
    });
    poll(cx);
    cx.timer.every(3000, poll);
  }

  render() {
    this.watchers.sync();
    const value = this.watchers.current();
    const t = theme();
    const color = value.state === "failed" ? t.blocked
      : value.state === "passed" ? t.accent
      : value.state === "running" ? t.foreground : t.muted;
    const generation = value.generation === undefined ? "" : ` #${value.generation}`;
    const failures = value.failures ? ` · ${value.failures} failures` : "";

    return h_flex().size_full().px(10).items_center()
      .bg(t.chrome).border_t(1).border_color(t.border).text_size(11.8)
      .child(div().truncate().text_color(color).child(`fzz ${value.state}${generation}${failures}`));
  }
}
