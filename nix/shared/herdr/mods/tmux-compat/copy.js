export function copyPlan(focus, appHome, home) {
  if (!focus?.pane || !/^(?:[A-Za-z0-9_.-]+\/)?t[a-z0-9]+$/.test(focus.terminal ?? "")) {
    throw new Error("Focus a terminal before opening copy mode.");
  }
  const script = `${appHome}/mods/tmux-compat/copy_mode.py`;
  return {
    cwd: home, script, command: ["python3", script], args: ["--terminal", focus.terminal],
    dependencies: ["python3", "hc", "nvim"],
    title: "COPY MODE · hjkl move · / search · v select · y copy · q exit",
    missingMessage: "Restore executable copy_mode.py from your dotfiles checkout and rerun Stow.",
  };
}
