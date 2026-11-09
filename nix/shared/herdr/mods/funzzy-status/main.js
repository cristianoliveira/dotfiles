import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { spaces, panes, hc, run, exec, notify, theme, props, home } from "herdr";
import { ProjectWatchers } from "./projects.js";
import { watcherBinary, statusColor } from "./model.js";
import { WatcherLocations } from "./location.js";

export default class FunzzyStatus extends View {
  init(_props, cx) {
    const options = props() ?? {};
    const binary = watcherBinary(options.binary, home());
    const remoteBinary = typeof options.remoteBinary === "string" && options.remoteBinary
      ? options.remoteBinary : "fzz";
    this.locations = new WatcherLocations({ spaces, panes, core: hc, run });
    this.watchers = new ProjectWatchers({ spaces, exec, notify, binary, remoteBinary,
      locate: (folder) => this.locations.unique(folder),
    });
    const poll = (cx) => {
      if (this.polling) return;
      this.polling = true;
      cx.spawn(async (cx) => {
        try {
          await this.locations.refresh();
          await this.watchers.poll();
          cx.notify();
        } finally {
          this.polling = false;
        }
      });
    };
    poll(cx);
    cx.timer.every(3000, poll);
  }

  render() {
    this.watchers.sync();
    const value = this.watchers.current();
    const folder = spaces().find((space) => space.active && !space.machine)?.folder;
    const matches = this.locations.forFolder(folder);
    const target = this.locations.unique(folder);
    const location = target ? ` · ${target.name}` : matches.length > 1 ? ` · ${matches.length} watchers` : "";
    const t = theme();
    const color = statusColor(value.state, t);
    const generation = value.generation === undefined ? "" : ` #${value.generation}`;
    const failures = value.failures ? ` · ${value.failures} failures` : "";

    return h_flex().size_full().px(6).items_center()
      .bg(t.chrome).border_t(1).border_color(t.border).text_size(11.8)
      .when(Boolean(target), (el) => el.cursor_pointer()
        .tooltip(`Open watcher in ${target.name}`)
        .on_click(() => {
          const current = this.locations.unique(folder);
          if (current) run("pane.focus", { terminal: current.terminal });
        }))
      .child(div().truncate().text_color(color).child(`fzz ${value.state}${generation}${failures}${location}`));
  }
}
