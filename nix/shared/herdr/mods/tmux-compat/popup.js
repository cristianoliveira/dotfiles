export const POPUP_LABEL = "dotfiles.tmux-popup";

export function popupPresentation(kind) {
  if (kind === "broadcast") {
    return { kind: "popup", at: { x: 48, y: 16 }, width: 240, height: 32 };
  }
  if (kind === "kill-port") return { kind: "dialog", width: 0.5, height: 0.4 };
  return { kind: "dialog", width: 0.85, height: 0.75 };
}

export function popupPlan(focus, spaces) {
  if (!focus?.pane || !focus.terminal || !focus.cwd?.startsWith("/")) {
    throw new Error("Focus a terminal with a known absolute working directory first.");
  }
  const space = spaces.find((space) => space.id === focus.space);
  if (!space || space.machine) throw new Error("Project popups currently support local spaces only.");

  return { cwd: focus.cwd, script: `${focus.cwd.replace(/\/+$/, "")}/.tmp/popup` };
}

export function killPortPlan(focus, spaces, home) {
  const { cwd } = popupPlan(focus, spaces);
  if (typeof home !== "string" || !home.startsWith("/")) throw new Error("A known absolute home directory is required.");
  return {
    cwd,
    script: `${home.replace(/\/+$/, "")}/.dotfiles/tmux/scripts/kill-port.sh`,
    dependencies: ["bash", "lsof", "fzf"],
    missingMessage: "Restore executable ~/.dotfiles/tmux/scripts/kill-port.sh from your dotfiles checkout.",
  };
}

function validateAddress(address) {
  if (typeof address !== "string" || !/^t[a-z0-9]+$/.test(address)) {
    throw new Error("Core returned an invalid local popup terminal address.");
  }
}

function parseReply(result) {
  try {
    return JSON.parse(result.stdout || result.stderr);
  } catch {
    throw new Error(result.stderr.trim() || "Herdr core returned an invalid JSON reply.");
  }
}

function data(result) {
  const value = parseReply(result);
  if (result.code !== 0 || value.error) {
    throw new Error(value.error?.message || result.stderr || "Herdr core request failed.");
  }
  return value;
}

async function inspect(address, core) {
  const result = await core(["get", "--json", address]);
  const value = parseReply(result);
  if (result.code !== 0 && value.error?.kind === "not_found") return null;
  const record = data(result);
  if (record.address !== address) throw new Error("Core returned a mismatched terminal address.");
  return record;
}

export async function popupIsLive(address, core) {
  validateAddress(address);
  const record = await inspect(address, core);
  return Boolean(record && record.state === "live" && record.labels?.[POPUP_LABEL] === "1" && !record.keep);
}

export async function releasePopup(address, core) {
  validateAddress(address);
  const record = await inspect(address, core);
  if (!record || record.state !== "live" || record.labels?.[POPUP_LABEL] !== "1" || record.keep) return;

  const result = await core(["kill", address]);
  if (result.code !== 0) {
    // --rm can remove the terminal before kill's reply reaches the caller.
    if (await inspect(address, core) === null) return;
    data(result);
  }
}

export async function openPopup(plan, io) {
  if (!await io.check(plan.script)) {
    throw new Error(plan.missingMessage ?? `No executable script at ${plan.script}. From its project folder, run chmod +x .tmp/popup and add a shebang.`);
  }
  if (plan.dependencies && !await io.available(plan.dependencies)) {
    throw new Error(`Popup requires ${plan.dependencies.join(", ")}. Install the missing commands in your Nix environment before retrying.`);
  }
  // hc interprets a single argv string as shell text; env preserves a literal script path.
  const receipt = data(await io.core([
    "run", "--bg", "--json", "--no-parent", "--no-notify", "--rm",
    "--label", `${POPUP_LABEL}=1`, "--cwd", plan.cwd, "--", "env", "--",
    ...(plan.command ?? [plan.script]), ...(plan.args ?? []),
  ]));
  validateAddress(receipt.address);
  if (receipt.state !== "live") return null;

  try {
    const overlay = io.open(receipt.address);
    if (!overlay) throw new Error("Herdr could not open the terminal overlay.");
    return { address: receipt.address, overlay };
  } catch (error) {
    try {
      await releasePopup(receipt.address, io.core);
    } catch (cleanup) {
      throw new Error(`${error.message}; popup cleanup also failed: ${cleanup.message}`);
    }
    throw error;
  }
}
