export const REPEAT_TIMEOUT_MS = 1500;

const ACTIONS = {
  n: ["tab.prev"],
  p: ["tab.next"],
  h: ["pane.go", { direction: "left" }],
  j: ["pane.go", { direction: "down" }],
  k: ["pane.go", { direction: "up" }],
  l: ["pane.go", { direction: "right" }],
};

export class RepeatSession {
  constructor(close) {
    this.active = true;
    this.close = close;
    this.cancel = null;
  }

  arm(schedule) {
    if (!this.active) return;
    this.cancel?.();
    this.cancel = schedule(REPEAT_TIMEOUT_MS, () => this.finish());
  }

  press(key, schedule) {
    if (!this.active) return null;
    const plain = key.startsWith("ctrl-") ? key.slice(5) : key;
    const action = Object.hasOwn(ACTIONS, plain) ? ACTIONS[plain] : null;
    // Only Ctrl+h/j/k/l are pane aliases; Ctrl+n/p are not repeat shortcuts.
    if (!action || (key.startsWith("ctrl-") && (plain === "n" || plain === "p"))) {
      this.finish();
      return null;
    }
    this.arm(schedule);
    return action;
  }

  finish() {
    if (!this.active) return;
    this.dispose();
    this.close();
  }

  dispose() {
    this.active = false;
    this.cancel?.();
    this.cancel = null;
  }
}
