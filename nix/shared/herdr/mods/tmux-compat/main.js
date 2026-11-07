import { View, div } from "gpui-kit";
import { spaces, shared, setShared, nextCommand, run, notify } from "herdr";
import { observeSpaces, lastSpace } from "./history.js";

const HISTORY = "tmux-compat.space-history";

export default class TmuxCompat extends View {
  init(_props, cx) {
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        cx.notify();
        if (command !== "last-space") continue;

        const target = lastSpace(this.observe());
        if (target) run("space.select", { id: target });
        else notify({ title: "No previous space", body: "Visit another space first.", level: "info" });
      }
    });
  }

  observe() {
    const previous = shared(HISTORY) ?? [];
    const history = observeSpaces(previous, spaces());
    if (JSON.stringify(history) !== JSON.stringify(previous)) setShared(HISTORY, history);
    return history;
  }

  render() {
    this.observe();
    return div().id("tmux-compat").h(1);
  }
}
