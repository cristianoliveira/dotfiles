export const POPUP_LABEL = "dotfiles.tmux-popup";

export function popupPlan(focus, spaces) {
  if (!focus?.pane || !focus.terminal || !focus.cwd?.startsWith("/")) {
    throw new Error("Focus a terminal with a known absolute working directory first.");
  }
  const space = spaces.find((space) => space.id === focus.space);
  if (!space || space.machine) throw new Error("Project popups currently support local spaces only.");

  return { cwd: focus.cwd, script: `${focus.cwd.replace(/\/+$/, "")}/.tmp/popup` };
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
    throw new Error(`No executable script at ${plan.script}. From its project folder, run chmod +x .tmp/popup and add a shebang.`);
  }
  // hc interprets a single argv string as shell text; env preserves a literal script path.
  const receipt = data(await io.core([
    "run", "--bg", "--json", "--no-parent", "--no-notify", "--rm",
    "--label", `${POPUP_LABEL}=1`, "--cwd", plan.cwd, "--", "env", "--", plan.script,
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
