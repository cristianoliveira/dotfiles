import { View, div } from "gpui-kit";
import { spaces, focused, shared, setShared, nextCommand, run, notify, openOverlay, closeOverlay, props, hc, exec, home, appHome, panes, terminals } from "herdr";
import { observeSpaces, lastSpace, observeTabs, lastTab, observeRecentTabs } from "./history.js";
import { folderTabName } from "./rename.js";
import { RepeatMode } from "./repeat-view.js";
import { CloseSpacesMode } from "./close-spaces-view.js";
import { PopupHeader } from "./popup-header.js";
import { popupPlan, killPortPlan, openPopup, releasePopup, popupIsLive, popupPresentation } from "./popup.js";
import { broadcastPlan } from "./broadcast.js";
import { copyPlan } from "./copy.js";
import { moveTab } from "./move-tab.js";
import { MoveTabMode } from "./move-tab-view.js";
import { rotateTabPanes } from "./rotate.js";
import { shrinkPaneHeight } from "./pane-size.js";

const HISTORY = "tmux-compat.space-history";
const TAB_HISTORY = "tmux-compat.tab-history";

export default class TmuxCompat extends View {
  init(_props, cx) {
    const options = props();
    if (options?.mode === "move-tab") this.mode = new MoveTabMode(options, cx);
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
        if (command === "move-tab-left") moveTab(spaces(), -1, run);
        if (command === "move-tab-right") moveTab(spaces(), 1, run);
        if (command === "move-tab-to") this.promptTabPosition();
        if (command === "rotate-panes") this.rotatePanes(cx);
        if (command === "shrink-height") this.shrinkPane(cx);
        if (command === "rename-from-folder") this.renameFromFolder();
        if (command === "repeat") openOverlay({ mod: "tmux-compat", props: { mode: "repeat" }, kind: "popup", width: 580, height: 108 });
        if (command === "close-spaces") openOverlay({ mod: "tmux-compat", props: { mode: "close-spaces" }, kind: "dialog", modal: true, width: 700, height: 480 });
        if (command === "popup") this.togglePopup(cx);
        if (command === "kill-port") this.togglePopup(cx, "kill-port");
        if (command === "broadcast") this.togglePopup(cx, "broadcast");
        if (command === "copy-mode") this.togglePopup(cx, "copy-mode");
      }
    });
  }

  togglePopup(cx, kind = "project") {
    if (this.popupOpening || this.closing) return;
    const context = { focus: focused(), spaces: spaces(), panes: panes(), terminals: terminals() };
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
        const broadcast = kind === "broadcast";
        const copyMode = kind === "copy-mode";
        let plan;
        if (copyMode) plan = copyPlan(context.focus, appHome(), home());
        else if (broadcast) plan = broadcastPlan(context.focus, context.spaces, context.panes, context.terminals, appHome());
        else if (killPort) plan = killPortPlan(context.focus, context.spaces, home());
        else plan = popupPlan(context.focus, context.spaces);
        if (broadcast && (await exec("python3", ["-I", "-c", "import curses"])).code !== 0) {
          throw new Error("Broadcast needs Python 3 with curses support in your Nix environment.");
        }
        const shortcut = copyMode ? "Ctrl+A [" : broadcast ? "Ctrl+A e" : killPort ? "Ctrl+A Shift+P" : "Ctrl+A Space";
        this.popup = await openPopup(plan, {
          core: hc,
          check: async (script) => (await exec("test", ["-f", script, "-a", "-x", script])).code === 0,
          available: async (commands) => (await exec("sh", ["-c",
            'for name do command -v "$name" >/dev/null || exit 1; done',
            "popup-dependencies", ...commands,
          ])).code === 0,
          open: (address) => {
            if (this.closing) throw new Error("Popup owner closed during startup.");
            if (broadcast) return openOverlay({ ...popupPresentation(kind), layout: {
              type: "column", terminal_padding: [4, 4], children: [
                // Keep the cleanup owner mounted without drawing a title bar.
                { type: "block", size: { px: 1 }, content: {
                  mod: "tmux-compat", props: { mode: "popup-header", address, hidden: true },
                } },
                { type: "block", content: { terminal: address } },
              ],
            } });
            return openOverlay({ ...popupPresentation(kind), layout: {
              type: "column",
              children: [
                { id: "popup-header", type: "block", size: { px: 36 }, content: {
                  mod: "tmux-compat", props: { mode: "popup-header", address, script: plan.title ?? plan.script, shortcut },
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

  rotatePanes(cx) {
    if (this.rotating || this.resizing) return;
    this.rotating = true;
    cx.spawn(async (cx) => {
      try {
        await rotateTabPanes({ focused, spaces, panes, appHome, exec, run,
          nativeRotation: (props()?.native_rotation ?? props()?.native_pair_rotation) !== false,
        });
      } catch (error) {
        notify({ title: "Pane rotation failed", body: error.message, level: "error" });
      } finally {
        this.rotating = false;
        cx.notify();
      }
    });
  }

  shrinkPane(cx) {
    if (this.rotating || this.resizing) return;
    this.resizing = true;
    cx.spawn(async (cx) => {
      try {
        await shrinkPaneHeight({ focused, spaces, panes, appHome, exec, run });
      } catch (error) {
        notify({ title: "Pane resize failed", body: error.message, level: "error" });
      } finally {
        this.resizing = false;
        cx.notify();
      }
    });
  }

  promptTabPosition() {
    const space = spaces().find(space => space.active);
    const tab = space?.tabs.find(tab => tab.active);
    if (!tab) return;

    openOverlay({ mod: "tmux-compat", props: {
      mode: "move-tab", target: { spaceId: space.id, tabId: tab.id },
    }, kind: "dialog", modal: true, width: 520, height: 160 });
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
    const recent = shared("tmux-compat.recent-tabs") ?? [];
    const nextRecent = observeRecentTabs(recent, snapshot);
    if (JSON.stringify(recent) !== JSON.stringify(nextRecent)) setShared("tmux-compat.recent-tabs", nextRecent);
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
    await this.mode?.close?.();
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
