import { View, div } from "gpui-kit";
import { v_flex, h_flex, Input, InputState } from "gpui-base";
import { appHome, home, exec, focused, spaces, theme, props, closeOverlay } from "herdr";

export default class VideoPreview extends View {
  init(options = {}, cx) {
    const context = focused();
    const space = spaces().find(space => space.id === context?.space);
    // This mod opens local files only; never reinterpret a remote cwd locally.
    this.cwd = space?.machine ? home() : context?.cwd || space?.folder || home();
    this.busy = false;
    this.error = "";
    this.message = "";
    this.handle = cx.focus_handle();
    this.input = InputState.new({ value: options.path || "", placeholder: "Local video path (MP4, MOV, MKV, WebM…)" });
    this.input.on("submit", (_event, cx) => this.open(cx));
    this.input.focus();
    if (options.path) this.open(cx);
    else cx.spawn(async cx => {
      try {
        const data = await this.helper(["--clipboard"]);
        if (data.path && !this.input.value() && !this.busy) {
          this.input.set_value(data.path);
          this.open(cx);
        }
      } catch { /* Manual paste works without a clipboard utility. */ }
      cx.notify();
    });
  }

  async helper(args) {
    const result = await exec("python3", [`${appHome()}/mods/video-preview/video.py`, ...args]);
    let data;
    try { data = JSON.parse(result.stdout); }
    catch { throw new Error(result.stderr?.trim() || "Video helper returned invalid JSON."); }
    if (result.code !== 0 || !data.ok) throw new Error(data.error || "Video preview could not start.");
    return data;
  }

  open(cx) {
    if (this.busy) return;
    const path = this.input.value().trim();
    if (!path) { this.error = "Paste a local video path or drop a video file here."; cx.notify(); return; }
    this.busy = true;
    this.error = "";
    cx.spawn(async cx => {
      try {
        const data = await this.helper(["--cwd", this.cwd, "--", path]);
        if (data.state === "launched") {
          this.busy = false;
          closeOverlay(props().overlay);
          return;
        }
        this.message = "The player closed. Choose another video to preview.";
      } catch (error) { this.error = error.message; }
      this.busy = false;
      cx.notify();
    });
  }

  render() {
    const t = theme();
    return v_flex().id("video-preview").track_focus(this.handle).size_full().p(18).gap(14).overflow_y_scrollbar()
      .bg(t.popover).text_size(13)
      .on_key_down((event, cx) => {
        if (event.key !== "escape") return;
        closeOverlay(props().overlay);
        cx.stop_propagation();
      })
      .on_drop((event, cx) => {
        if (this.busy || !event.paths?.length) return;
        this.input.set_value(event.paths[0]);
        this.open(cx);
      })
      .child(h_flex().justify_between().items_center()
        .child(div().font_semibold().text_color(t.foreground).child("Video Preview · local files"))
        .child(div().id("video-close").cursor_pointer().text_color(t.muted).child("Close · Esc")
          .on_click(() => closeOverlay(props().overlay))))
      .child(div().text_color(t.muted).child("Opens a large, independent mpv window. Starts paused; no unexpected audio."))
      .child(h_flex().gap(8).items_center()
        .child(Input.new(this.input).h(36).flex_1().px(10).bg(t.background).text_color(t.foreground).rounded(5))
        .child(div().id("video-open").px(10).py(8).rounded(5).bg(t.selected).text_color(t.foreground)
          .cursor_pointer().child(this.busy ? "Opening…" : "Open paused · Enter").on_click((_event, cx) => this.open(cx))))
      .child(div().text_color(t.dim).child("Copy a video path before opening, paste a path above, or drop a local video here."))
      .child(div().text_size(11).text_color(t.muted).child("Player: Space play/pause · ←/→ seek · F fullscreen · Esc close"))
      .when(Boolean(this.error), root => root.child(div().text_color(t.blocked).child(this.error)))
      .when(Boolean(this.message), root => root.child(div().text_color(t.muted).child(this.message)));
  }
}
