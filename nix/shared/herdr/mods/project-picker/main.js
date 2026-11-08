import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, v_virtual_list, VirtualListScrollHandle } from "gpui-base";
import { appHome, home, exec, spaces, run, theme, props, closeOverlay, shared, setShared } from "herdr";
import { filterProjects, projectCommand, projectKey } from "./model.js";
import { refreshProjects, restoreProjectCache } from "./discovery.js";

const CACHE_KEY = "project-picker.cache";

export default class ProjectPicker extends View {
  init(_props, cx) {
    const cache = restoreProjectCache(shared(CACHE_KEY));
    this.projects = cache.flatMap(entry => entry.projects.map(project => ({ ...project, machine: entry.machine })));
    this.loading = true;
    this.query = "";
    this.at = 0;
    this.message = "Loading projects…";
    this.warning = "";
    this.opening = false;
    this.handle = cx.focus_handle();
    this.scroll = VirtualListScrollHandle.new();
    this.input = InputState.new({ placeholder: "Search machines and projects…" });
    this.input.on("change", (_event, cx) => {
      this.query = this.input.value();
      this.at = 0;
      this.scroll.scroll_to_item(0);
      cx.notify();
    });
    this.input.on("submit", () => this.choose(this.rows()[this.at]));
    this.input.focus();

    cx.spawn(async (cx) => {
      let names = ["", ...cache.map(entry => entry.machine)];
      let machineWarning = "";
      try {
        const result = await exec("python3", [
          `${appHome()}/mods/project-picker/projects.py`, home(), "[]", "--list-machines",
        ]);
        if (result.code !== 0) throw new Error("Cannot list machines; check hc machine ls.");
        const machines = JSON.parse(result.stdout).machines;
        if (!Array.isArray(machines)) throw new Error("Invalid machine list; check hc machine ls.");
        names = ["", ...machines.filter(machine => typeof machine === "string" && machine)];
      } catch (error) {
        machineWarning = error.message;
      }
      await refreshProjects({
        cache, machines: names,
        scan: async machine => {
          const result = await exec("python3", [
            `${appHome()}/mods/project-picker/projects.py`, home(), JSON.stringify(spaces()),
            ...(machine ? ["--remote", machine] : []),
          ]);
          if (result.code !== 0) throw new Error(result.stderr.trim() || "Project discovery failed");
          return JSON.parse(result.stdout);
        },
        publish: state => {
          const selected = this.rows()[this.at];
          this.projects = state.projects;
          if (selected) {
            const at = this.rows().findIndex(project => projectKey(project) === projectKey(selected));
            this.at = at >= 0 ? at : 0;
          }
          this.loading = state.loading;
          this.warning = [machineWarning, ...state.warnings].filter(Boolean).join("\n");
          this.message = state.loading ? "Loading projects…" : "No projects found on available machines.";
          cx.notify();
        },
        persist: entry => {
          const entries = restoreProjectCache(shared(CACHE_KEY)).filter(cached => cached.machine !== entry.machine);
          setShared(CACHE_KEY, { version: 1, entries: [...entries, entry] });
        },
      });
    });
  }

  rows() {
    return filterProjects(this.projects, this.query);
  }

  choose(project) {
    if (this.opening) return;
    const command = projectCommand(project, spaces());
    if (!command) return;

    this.opening = true;
    run(...command);
    closeOverlay(props().overlay);
  }

  render() {
    const t = theme();
    const rows = this.rows();
    this.at = Math.max(0, Math.min(this.at, rows.length - 1));

    return v_flex()
      .id("project-picker")
      .track_focus(this.handle)
      .w_full().h(440).p(16).gap(10).bg(t.popover).text_size(13)
      .on_key_down((event, cx) => {
        if (event.key === "escape") {
          closeOverlay(props().overlay);
        } else if (["ctrl-j", "ctrl-k"].includes(event.keystroke) || event.key === "down" || event.key === "up") {
          const step = event.key === "down" || event.keystroke === "ctrl-j" ? 1 : -1;
          this.at = rows.length ? (this.at + step + rows.length) % rows.length : 0;
          this.scroll.scroll_to_item(this.at, "center");
        } else {
          return;
        }
        cx.stop_propagation();
        cx.notify();
      })
      .child(h_flex().justify_between().items_center()
        .child(div().font_semibold().text_color(t.foreground).child("Projects"))
        .child(div().text_color(t.dim).child("Ctrl+A → Ctrl+P")))
      .child(Input.new(this.input).h(36).w_full().px(10)
        .bg(t.background).text_color(t.foreground).rounded(6))
      .child(rows.length
        ? v_virtual_list("project-list", rows.length, 32, (index) => projectKey(rows[index]),
          (range) => rows.slice(range.start, range.end).map((project, offset) =>
            h_flex().h(32).px(10).items_center().justify_between().rounded(5)
              .bg(range.start + offset === this.at ? t.hover : t.popover)
              .child(div().truncate().text_color(t.foreground).child(project.label))
              .child(div().text_color(t.dim).child(`${project.machine || "local"} · ${project.spaceId ? "open" : "new"}`))))
          .h(300).w_full().track_scroll(this.scroll)
          .on_item_click((key) => this.choose(rows.find((project) => projectKey(project) === key)))
        : div().flex_1().text_color(t.muted)
          .child(this.projects.length ? "No matching projects." : this.message))
      .when(Boolean(this.warning), (element) => element.child(
        div().text_color(t.muted).child(this.warning)))
      .child(div().text_size(11).text_color(t.dim)
        .child(`${rows.length} projects${this.loading ? " · refreshing…" : ""} · ↑/↓ or Ctrl-j/k select · Enter open · Esc cancel`));
  }
}
