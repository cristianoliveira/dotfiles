import { View, div } from "gpui-kit";
import { v_flex, h_flex, Input, InputState, v_virtual_list, VirtualListScrollHandle } from "gpui-base";
import { appHome, exec, focused, spaces, theme, props, closeOverlay } from "herdr";
import { startArgs, matchingTunnel } from "./model.js";

export default class PortForward extends View {
  init(_options, cx) {
    this.machine = spaces().find(space => space.id === focused()?.space)?.machine || "";
    this.machines = [];
    this.ports = [];
    this.tunnels = [];
    this.at = -1;
    this.revision = 0;
    this.discoveryRevision = 0;
    this.busy = false;
    this.checking = false;
    this.discovering = false;
    this.loadingMachines = false;
    this.error = "";
    this.message = "";
    this.handle = cx.focus_handle();
    this.scroll = VirtualListScrollHandle.new();
    this.port = InputState.new({ placeholder: "Remote port" });
    this.local = InputState.new({ placeholder: "Local (same by default)" });
    this.port.on("change", (_event, cx) => cx.notify());
    this.local.on("change", (_event, cx) => cx.notify());
    this.port.on("submit", (_event, cx) => this.toggle(cx));
    this.local.on("submit", (_event, cx) => this.toggle(cx));
    this.port.focus();
    this.refresh(cx);
    cx.timer.every(5000, cx => this.sync(cx));
  }

  async helper(args) {
    const result = await exec("python3", [
      `${appHome()}/mods/port-forward/forward.py`, "--state-dir", `${appHome()}/data/port-forward`, ...args,
    ]);
    let data;
    try { data = JSON.parse(result.stdout); }
    catch { throw new Error(result.stderr?.trim() || "Port-forward helper returned invalid JSON."); }
    if (result.code !== 0 || !data.ok) throw new Error(data.error || "Port-forward operation failed.");
    return data;
  }

  sync(cx, showError = false) {
    if (this.busy || this.checking) return;
    this.checking = true;
    const revision = this.revision;
    cx.spawn(async cx => {
      try {
        const data = await this.helper(["status"]);
        if (revision === this.revision) this.tunnels = data.tunnels;
      }
      catch (error) { if (showError) this.error = error.message; }
      this.checking = false;
      cx.notify();
    });
  }

  refresh(cx) {
    this.sync(cx, true);
    if (this.loadingMachines) return;
    this.loadingMachines = true;
    cx.spawn(async cx => {
      try {
        this.machines = (await this.helper(["machines"])).machines;
        if (!this.machines.some(machine => machine.name === this.machine && machine.supported)) {
          this.machine = this.machines.find(machine => machine.supported && machine.state === "connected")?.name || "";
        }
        this.discover(cx);
      } catch (error) { this.error = error.message; }
      this.loadingMachines = false;
      cx.notify();
    });
  }

  discover(cx) {
    if (!this.machine) return;
    const machine = this.machine;
    const revision = ++this.discoveryRevision;
    this.discovering = true;
    this.error = "";
    cx.spawn(async cx => {
      try {
        const data = await this.helper(["list", "--machine", machine]);
        if (this.discoveryRevision === revision) this.ports = data.ports;
      } catch (error) {
        if (this.discoveryRevision === revision) this.error = error.message;
      }
      if (this.discoveryRevision === revision) this.discovering = false;
      cx.notify();
    });
  }

  selectMachine(machine, cx) {
    if (this.busy) return;
    if (!machine.supported) {
      this.error = "This machine needs an SSH target; custom --via transports are not supported.";
      cx.notify();
      return;
    }
    this.machine = machine.name;
    this.ports = [];
    this.at = -1;
    this.port.set_value("");
    this.local.set_value("");
    this.port.focus();
    this.discover(cx);
    cx.notify();
  }

  choose(index, cx) {
    if (!this.ports.length) return;
    this.at = (index + this.ports.length) % this.ports.length;
    this.port.set_value(String(this.ports[this.at].port));
    this.scroll.scroll_to_item(this.at, "center");
    this.port.focus();
    cx.notify();
  }

  toggle(cx) {
    try {
      const match = matchingTunnel(this.tunnels, this.machine, this.port.value(), this.local.value());
      const args = match?.state === "forwarding" ? ["stop", "--id", match.id]
        : startArgs(this.machine, this.port.value(), this.local.value());
      this.perform(args, cx);
    } catch (error) { this.error = error.message; cx.notify(); }
  }

  perform(args, cx) {
    if (this.busy) return;
    this.busy = true;
    this.revision++;
    this.error = "";
    cx.spawn(async cx => {
      try {
        const result = await this.helper(args);
        if (result.tunnel) {
          let label = "Tunnel disconnected";
          if (result.tunnel.state === "forwarding") label = result.reused ? "Already forwarding" : "Forwarding";
          this.message = `${label}: ${result.tunnel.local_url} · application unchecked`;
        } else {
          this.message = args[0] === "stop" ? "Tunnel stopped; remote server is unchanged." : "Browser opened; application health is unchecked.";
        }
        this.tunnels = (await this.helper(["status"])).tunnels;
      } catch (error) { this.error = error.message; }
      this.busy = false;
      cx.notify();
    });
  }

  button(id, text, action, t) {
    return div().id(id).px(10).py(6).rounded(5).bg(t.background).text_color(t.foreground)
      .cursor_pointer().child(text).on_click(action);
  }

  render() {
    const t = theme();
    const match = matchingTunnel(this.tunnels, this.machine, this.port.value(), this.local.value());
    return v_flex().id("port-forward").track_focus(this.handle).size_full().p(16).gap(10)
      .overflow_y_scrollbar().bg(t.popover).text_size(13)
      .on_key_down((event, cx) => {
        if (event.key === "escape") closeOverlay(props().overlay);
        else if (event.key === "down" || event.keystroke === "ctrl-j") this.choose(this.at + 1, cx);
        else if (event.key === "up" || event.keystroke === "ctrl-k") this.choose(this.at < 0 ? this.ports.length - 1 : this.at - 1, cx);
        else return;
        cx.stop_propagation();
      })
      .child(h_flex().flex_none().justify_between().items_center()
        .child(div().font_semibold().text_color(t.foreground).child("Port Forward · localhost only"))
        .child(h_flex().gap(8)
          .child(this.button("forward-refresh", "Refresh", (_event, cx) => this.refresh(cx), t))
          .child(this.button("forward-close", "Close · Esc", () => closeOverlay(props().overlay), t))))
      .child(h_flex().flex_none().gap(8).children(this.machines.map(machine =>
        this.button(`forward-machine-${machine.name}`, `${machine.name}${machine.supported ? "" : " (unsupported)"}`,
          (_event, cx) => this.selectMachine(machine, cx), t)
          .bg(machine.name === this.machine ? t.selected : t.background))))
      .child(h_flex().flex_none().gap(8).items_center()
        .child(Input.new(this.port).h(36).w(140).px(8).bg(t.background).text_color(t.foreground).rounded(5))
        .child(Input.new(this.local).h(36).w(210).px(8).bg(t.background).text_color(t.foreground).rounded(5))
        .child(this.button("forward-toggle", this.busy ? "Working…" : match?.state === "forwarding" ? "Stop · Enter" : "Forward · Enter",
          (_event, cx) => this.toggle(cx), t)))
      .child(div().flex_none().text_color(t.muted).child(this.discovering
        ? `Checking ${this.machine}… You can still enter a port manually.` : `Listening ports on ${this.machine || "a selected machine"} · click or ↑/↓ to select`))
      .child(this.ports.length ? v_virtual_list("forward-ports", this.ports.length, 32, index => String(this.ports[index].port),
        range => this.ports.slice(range.start, range.end).map(port =>
          h_flex().h(32).px(8).gap(12).items_center().rounded(4)
            .bg(String(port.port) === this.port.value() ? t.hover : t.background)
            .child(div().w(64).text_color(t.foreground).child(String(port.port)))
            .child(div().flex_1().text_color(t.muted).child(port.process || "TCP listener"))
            .child(div().text_color(t.dim).child(port.address))))
          .h(200).flex_none().w_full().track_scroll(this.scroll)
          .on_item_click((port, cx) => this.choose(this.ports.findIndex(item => String(item.port) === port), cx))
        : div().flex_none().text_color(t.dim).child("No discovered ports. Enter a port above, or Refresh."))
      .child(div().flex_none().font_semibold().text_color(t.foreground).child("Owned tunnels · stays on after closing this popup"))
      .children(this.tunnels.map(tunnel => h_flex().flex_none().items_center().gap(8).p(8).rounded(5).bg(t.background)
        .child(v_flex().flex_1().gap(3)
          .child(div().text_color(tunnel.state === "forwarding" ? t.done : t.blocked)
            .child(`127.0.0.1:${tunnel.local_port} → ${tunnel.machine}:${tunnel.remote_port} · ${tunnel.state}`))
          .child(div().text_size(11).text_color(t.dim).child(`${tunnel.origin} · application health unchecked`)))
        .when(tunnel.state === "forwarding", row => row.child(this.button(`forward-open-${tunnel.id}`, "Browser",
          (_event, cx) => this.perform(["open", "--id", tunnel.id], cx), t)))
        .when(tunnel.state !== "forwarding", row => row.child(this.button(`forward-reconnect-${tunnel.id}`, "Reconnect",
          (_event, cx) => this.perform(startArgs(tunnel.machine, tunnel.remote_port, tunnel.local_port), cx), t)))
        .child(this.button(`forward-stop-${tunnel.id}`, "Stop", (_event, cx) => this.perform(["stop", "--id", tunnel.id], cx), t))))
      .when(!this.tunnels.length, root => root.child(div().flex_none().text_color(t.dim).child("No owned tunnels. Agent-started tunnels appear here too.")))
      .when(Boolean(this.error), root => root.child(div().flex_none().text_color(t.blocked).child(this.error)))
      .when(Boolean(this.message), root => root.child(div().flex_none().text_color(t.muted).child(this.message)));
  }
}
