import { View, div } from "gpui-kit";
import { spaces, focused, shared, setShared, nextCommand, run, notify, openOverlay, props } from "herdr";
import { observeSpaces, lastSpace, observeTabs, lastTab } from "./history.js";
import { folderTabName } from "./rename.js";
import { RepeatMode } from "./repeat-view.js";
import { CloseSpacesMode } from "./close-spaces-view.js";

const HISTORY = "tmux-compat.space-history";
const TAB_HISTORY = "tmux-compat.tab-history";

export default class TmuxCompat extends View {
  init(_props, cx) {
    const options = props();
    if (options?.mode === "repeat") this.mode = new RepeatMode(options, cx);
    if (options?.mode === "close-spaces") this.mode = new CloseSpacesMode(options, cx);
    if (this.mode) return;
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        cx.notify();
        const history = this.observe();
        if (command === "last-space") this.selectLast("space", lastSpace(history.spaces));
        if (command === "last-tab") this.selectLast("tab", lastTab(history.tabs, history.spaceId));
        if (command === "rename-from-folder") this.renameFromFolder();
        if (command === "repeat") openOverlay({ mod: "tmux-compat", props: { mode: "repeat" }, kind: "popup", width: 580, height: 108 });
        if (command === "close-spaces") openOverlay({ mod: "tmux-compat", props: { mode: "close-spaces" }, kind: "dialog", modal: true, width: 700, height: 480 });
      }
    });
  }

  renameFromFolder() {
    const target = folderTabName(focused());
    if (target) run("tab.rename", target);
    else notify({ title: "No terminal folder", body: "Focus a terminal with a known working directory first.", level: "info" });
  }

  selectLast(kind, target) {
    if (target) run(`${kind}.select`, { id: target });
    else notify({ title: `No previous ${kind}`, body: `Visit another ${kind} first.`, level: "info" });
  }

  observe() {
    const snapshot = spaces();
    const previousSpaces = shared(HISTORY) ?? [];
    const previousTabs = shared(TAB_HISTORY) ?? {};
    const spaceHistory = observeSpaces(previousSpaces, snapshot);
    const tabHistory = observeTabs(previousTabs, snapshot);
    if (JSON.stringify(spaceHistory) !== JSON.stringify(previousSpaces)) setShared(HISTORY, spaceHistory);
    if (JSON.stringify(tabHistory) !== JSON.stringify(previousTabs)) setShared(TAB_HISTORY, tabHistory);
    return { spaces: spaceHistory, tabs: tabHistory, spaceId: snapshot.find((space) => space.active)?.id };
  }

  close() {
    this.mode?.close();
  }

  render() {
    if (this.mode) return this.mode.render();
    this.observe();
    return div().id("tmux-compat").h(1);
  }
}
