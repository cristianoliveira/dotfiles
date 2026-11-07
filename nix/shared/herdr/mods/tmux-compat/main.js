import { View, div } from "gpui-kit";
import { spaces, focused, shared, setShared, nextCommand, run, notify, openOverlay, closeOverlay, props, hc, exec, home } from "herdr";
import { observeSpaces, lastSpace, observeTabs, lastTab } from "./history.js";
import { folderTabName } from "./rename.js";
import { RepeatMode } from "./repeat-view.js";
import { CloseSpacesMode } from "./close-spaces-view.js";
import { PopupHeader } from "./popup-header.js";
import { popupPlan, killPortPlan, openPopup, releasePopup, popupIsLive } from "./popup.js";

const HISTORY = "tmux-compat.space-history";
const TAB_HISTORY = "tmux-compat.tab-history";

export default class TmuxCompat extends View {
  init(_props, cx) {
    const options = props();
    if (options?.mode === "repeat") this.mode = new RepeatMode(options, cx);
    if (options?.mode === "close-spaces") this.mode = new CloseSpacesMode(options, cx);
    if (options?.mode === "popup-header") this.mode = new PopupHeader(options);
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
        if (command === "popup") this.togglePopup(cx);
        if (command === "kill-port") this.togglePopup(cx, "kill-port");
      }
    });
  }

  togglePopup(cx, kind = "project") {
    if (this.popupOpening || this.closing) return;
    const context = { focus: focused(), spaces: spaces() };
    this.popupOpening = true;
    cx.spawn(async (cx) => {
      try {
        if (this.popup) {
          const live = await popupIsLive(this.popup.address, hc);
          const previous = this.popup;
          this.popup = null;
          closeOverlay(previous.overlay);
          if (live) {
            await releasePopup(previous.address, hc);
            return;
          }
        }
        const killPort = kind === "kill-port";
        const plan = killPort
          ? killPortPlan(context.focus, context.spaces, home())
          : popupPlan(context.focus, context.spaces);
        const shortcut = killPort ? "Ctrl+A Shift+P" : "Ctrl+A Space";
        this.popup = await openPopup(plan, {
          core: hc,
          check: async (script) => (await exec("test", ["-f", script, "-a", "-x", script])).code === 0,
          available: async (commands) => (await exec("sh", ["-c",
            'for name do command -v "$name" >/dev/null || exit 1; done',
            "popup-dependencies", ...commands,
          ])).code === 0,
          open: (address) => {
            if (this.closing) throw new Error("Popup owner closed during startup.");
            return openOverlay({ kind: "dialog", width: killPort ? 0.5 : 0.85, height: killPort ? 0.4 : 0.75, layout: {
              type: "column",
              children: [
                { id: "popup-header", type: "block", size: { px: 36 }, content: {
                  mod: "tmux-compat", props: { mode: "popup-header", address, script: plan.script, shortcut },
                } },
                { id: "popup-terminal", type: "block", content: { terminal: address } },
              ],
            } });
          },
        });
      } catch (error) {
        notify({ title: "Terminal popup failed", body: error.message, level: "error" });
      } finally {
        this.popupOpening = false;
        cx.notify();
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

  async close() {
    this.closing = true;
    await this.mode?.close();
    if (this.popup) {
      closeOverlay(this.popup.overlay);
      await releasePopup(this.popup.address, hc);
    }
  }

  render() {
    if (this.mode) return this.mode.render();
    this.observe();
    return div().id("tmux-compat").h(1);
  }
}
