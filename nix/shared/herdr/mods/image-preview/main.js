import { View, div, image } from "gpui-kit";
import { v_flex, h_flex, Input, InputState } from "gpui-base";
import { appHome, exec, focused, spaces, machines, theme, props, closeOverlay } from "herdr";
import { imagePath, fitImage, previewAsset } from "./model.js";

export default class ImagePreview extends View {
  init(options = {}, cx) {
    const context = focused();
    const space = spaces().find(space => space.id === context?.space);
    this.machine = options.machine ?? space?.machine ?? "";
    this.cwd = options.cwd ?? (this.machine === (space?.machine || "")
      ? context?.cwd ?? space?.folder ?? "" : "");
    this.handle = cx.focus_handle();
    this.preview = null;
    this.error = "";
    this.loading = false;
    this.controls = true;
    const path = options.path ?? "";
    this.input = InputState.new({ value: path, placeholder: "Image path (PNG or JPEG)…" });
    this.input.on("submit", (_event, cx) => this.load(cx));
    this.input.focus();
    if (path) this.load(cx);
    else cx.spawn(async cx => {
      // Clipboard API is not granted to mods; use the platform's clipboard tool.
      try {
        const result = await exec("python3", [`${appHome()}/mods/image-preview/preview.py`, "--clipboard"]);
        const path = result.code === 0 ? JSON.parse(result.stdout).path : "";
        if (path && !this.input.value()) {
          this.input.set_value(imagePath(path));
          this.load(cx);
        }
      } catch { /* Manual paste remains available without a clipboard tool. */ }
      cx.notify();
    });
  }

  load(cx) {
    if (this.loading) return;
    let path;
    try { path = imagePath(this.input.value()); }
    catch (error) { this.error = error.message; cx.notify(); return; }
    this.loading = true;
    this.error = "";
    const machine = this.machine;
    cx.spawn(async cx => {
      try {
        const result = await exec("python3", [
          `${appHome()}/mods/image-preview/preview.py`, path,
          "--machine", machine, "--cwd", this.cwd,
          "--cache", `${appHome()}/image-previews`,
        ]);
        if (result.code !== 0) throw new Error(result.stderr.trim() || "Image could not be loaded.");
        const data = JSON.parse(result.stdout);
        this.preview = { ...data, asset: previewAsset(data), source: path, machine };
        this.controls = false;
        this.handle.focus();
      } catch (error) {
        this.error = error.message;
      }
      this.loading = false;
      cx.notify();
    });
  }

  selectMachine(machine, cx) {
    if (this.loading) return;
    this.machine = machine;
    this.controls = true;
    this.cwd = spaces().find(space => (space.machine || "") === machine && space.active)?.folder ?? "";
    this.preview = null;
    this.error = "";
    this.input.focus();
    cx.notify();
  }

  render() {
    const t = theme();
    const viewport = window.viewport_size();
    const width = viewport.width;
    const height = viewport.height;
    const editing = this.controls || !this.preview;
    const names = [...new Set(["", this.machine, ...machines().filter(machine => machine.layout === "ready")
      .map(machine => machine.name || "")])];
    const size = this.preview ? fitImage(this.preview.width, this.preview.height,
      Math.max(1, width - (editing ? 24 : 0)), Math.max(1, height - (editing ? 160 : 0))) : null;

    return v_flex().id("image-preview").track_focus(this.handle)
      .w(width).h(height).p(editing ? 12 : 0).gap(editing ? 8 : 0).bg(t.popover).text_size(13)
      .on_drop((event, cx) => {
        if (this.loading || !event.paths?.length) return;
        this.selectMachine("", cx);
        this.input.set_value(event.paths[0]);
        this.load(cx);
      })
      .on_key_down((event, cx) => {
        if (event.key === "escape") closeOverlay(props().overlay);
        else if (!editing && event.key === "e") {
          this.controls = true;
          this.input.focus();
          cx.notify();
        } else if (event.keystroke === "alt-m") {
          this.selectMachine(names[(names.indexOf(this.machine) + 1) % names.length], cx);
        } else return;
        cx.stop_propagation();
      })
      .when(editing, root => root.child(h_flex().justify_between().items_center()
        .child(div().font_semibold().text_color(t.foreground).child("Image preview"))
        .child(div().id("image-close").cursor_pointer().text_color(t.muted).child("Close · Esc")
          .on_click(() => closeOverlay(props().overlay))))
      .child(h_flex().gap(8).items_center().children(names.map(machine =>
        div().id(`image-machine-${machine || "local"}`).px(10).py(5).rounded(5).cursor_pointer()
          .bg(machine === this.machine ? t.selected : t.background).text_color(t.foreground)
          .child(machine || "local").on_click((_event, cx) => this.selectMachine(machine, cx)))))
      .child(h_flex().gap(8).items_center()
        .child(Input.new(this.input).h(36).flex_1().px(10).bg(t.background).text_color(t.foreground).rounded(5))
        .child(div().id("image-load").px(12).py(8).rounded(5).bg(t.selected).text_color(t.foreground)
          .cursor_pointer().child(this.loading ? "Loading…" : "Open · Enter").on_click((_event, cx) => this.load(cx)))))
      .child(div().relative().flex_1().min_h(0).w_full().overflow_hidden().bg(t.background)
        .flex().items_center().justify_center()
        .child(this.preview
          ? image(this.preview.asset).w(size.width).h(size.height)
          : div().text_color(t.muted).child(this.loading ? "Loading image…" : "Paste a path above, drop an image here, or copy its path before opening."))
        .when(!editing, canvas => canvas.child(h_flex().absolute().top(8).right(8).gap(12).px(10).py(6).rounded(5)
          .bg(t.popover).text_color(t.muted)
          .child(div().id("image-edit").cursor_pointer().child("Edit · E").on_click((_event, cx) => {
            this.controls = true;
            this.input.focus();
            cx.notify();
          }))
          .child(div().id("image-close").cursor_pointer().child("Close · Esc")
            .on_click(() => closeOverlay(props().overlay))))))
      .when(Boolean(this.error), element => element.child(div().text_color(t.blocked).child(this.error)))
      .when(editing, root => root.child(div().text_size(11).text_color(t.dim).truncate().child(this.preview
        ? `${this.preview.machine || "local"} · ${this.preview.source} · ${this.preview.width} × ${this.preview.height} · Alt-m machine · Esc close`
        : "PNG/JPEG · Up to 16 MiB / 25 megapixels · Drop image to open · Alt-m machine · Esc close")));
  }
}
