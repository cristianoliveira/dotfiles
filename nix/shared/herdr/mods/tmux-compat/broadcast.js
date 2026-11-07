import { popupPlan } from "./popup.js";

export function broadcastPlan(focus, spaces, panes, terminals, appHome) {
  const { cwd } = popupPlan(focus, spaces);
  if (focus.shown || typeof appHome !== "string" || !appHome.startsWith("/")) {
    throw new Error("Focus a normal local terminal pane before broadcasting.");
  }
  const members = panes.filter((pane) => pane.tab === focus.tab && pane.terminal);
  if (!members.some((pane) => pane.pane === focus.pane && pane.terminal === focus.terminal)) {
    throw new Error("The focused terminal is not a normal pane in this tab.");
  }
  const targets = [...new Map(members.map((pane) => [pane.terminal, {
    pane: pane.pane, terminal: pane.terminal,
  }])).values()];
  if (targets.length < 2 || targets.length > 8 || targets.some((target) =>
    !/^t[a-z0-9]+$/.test(target.terminal) ||
    !terminals.some((terminal) => terminal.address === target.terminal && terminal.state === "live"))) {
    throw new Error("Broadcast needs 2–8 live local terminal panes in the current tab.");
  }
  const script = `${appHome.replace(/\/+$/, "")}/mods/tmux-compat/broadcast.py`;
  return {
    cwd,
    script,
    command: ["python3", "-E", "-s", script],
    args: ["--targets", JSON.stringify(targets), "--space", focus.space, "--tab", focus.tab, "--app-home", appHome],
    title: `BROADCAST MODE · ${targets.map((target) => target.terminal).join(", ")}`,
    dependencies: ["python3", "hc", "herdr-app"],
    missingMessage: "Restore executable mods/tmux-compat/broadcast.py in your Herdr app configuration.",
  };
}
