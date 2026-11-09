const STATES = new Set(["idle", "running", "passed", "failed", "cancelled"]);

function validStatus(data) {
  return data && STATES.has(data.state)
    && Number.isSafeInteger(data.generation) && data.generation >= 0
    && Array.isArray(data.failures) && data.failures.every((item) => typeof item === "string");
}

export function statusColor(state, theme) {
  if (state === "running") return theme.ansi4;
  if (state === "passed") return theme.ansi2;
  if (state === "failed") return theme.ansi1;
  return theme.muted;
}

export function watcherBinary(binary = "fzz", home) {
  return binary.startsWith("~/") ? `${home}/${binary.slice(2)}` : binary;
}

// Transport is injected so the experiment has no dependency on other personal mods.
export class WatcherStatus {
  constructor({ activeSpace, exec, binary = "fzz" }) {
    this.activeSpace = activeSpace;
    this.exec = exec;
    this.binary = binary;
    this.revision = 0;
    this.busy = false;
    this.select();
  }

  select() {
    const space = this.activeSpace();
    const key = JSON.stringify([space?.id, space?.machine, space?.folder]);
    if (key === this.key) return;
    this.key = key;
    this.revision += 1;
    this.folder = space?.folder || null;
    this.machine = space?.machine || null;
    this.value = { state: this.folder ? "loading" : "no-project" };
  }

  async poll() {
    this.select();
    if (this.busy || !this.folder) return;
    this.busy = true;
    const revision = this.revision;
    const folder = this.folder;
    const machine = this.machine;
    const current = () => {
      this.select();
      return revision === this.revision;
    };
    const query = async (action) => {
      // Never invoke a shell or read job output. Herdr bounds exec to 30 s / 8 MiB.
      const options = machine ? { cwd: folder, on: machine } : { cwd: folder };
      const result = await this.exec(this.binary, ["ctl", "--format", "json", action], options);
      if (result.code !== 0) return null;
      return { data: JSON.parse(result.stdout) };
    };

    try {
      const capabilities = await query("capabilities");
      if (!current()) return;
      if (!capabilities) {
        this.value = { state: "offline" };
        return;
      }
      const data = capabilities.data;
      if (data?.schemaVersion !== 1 || !Array.isArray(data.methods) || !data.methods.includes("status")) {
        this.value = { state: "unsupported" };
        return;
      }
      const status = await query("status");
      if (!current()) return;
      if (!status) {
        this.value = { state: "offline" };
        return;
      }
      if (!validStatus(status.data)) {
        this.value = { state: "error" };
        return;
      }
      this.instance = typeof data.instance?.token === "string" ? data.instance.token : null;
      this.value = {
        state: status.data.state,
        generation: status.data.generation,
        failures: status.data.failures.length,
      };
    } catch (error) {
      if (current()) this.value = { state: error instanceof SyntaxError ? "error" : "offline" };
    } finally {
      this.busy = false;
    }
  }
}
