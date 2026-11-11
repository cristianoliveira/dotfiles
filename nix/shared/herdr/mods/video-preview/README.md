# Video Preview

Open a **local video** from a separate Herdr mod. The picker stays in Herdr;
actual playback uses the existing **mpv** player in a large, independent window.
Herdr does not expose a native video widget. This is real video playback with
seeking and sound, not an animated-image approximation.

## Use

1. Copy a local video file path.
2. Press **Ctrl-Shift-m**, or **Ctrl-a**, release Ctrl, then **m**.
3. The video opens **paused**, and the Herdr picker closes.
4. **Space** plays/pauses; **←/→** seek; **F** toggles fullscreen.
5. **Esc** or **Q** closes the player. Normal mpv mouse controls are available.

If no video path was copied, paste a path and press Enter, or drop a video
onto the picker. Clipboard **text paths** are supported, not clipboard media.
Each successful opening creates its own visible player window. No hidden
player daemon or shared player state is installed.

The player initially fits within 90% of the screen and preserves the full
video's aspect ratio without cropping. It is a separate OS window, not content
embedded in Herdr. Closing or switching Herdr does not close that window;
close the player explicitly. Once opening has been requested, dismissing the
picker does not cancel an already-running helper.

## Paths and limits

- Local files only. Remote Herdr space paths are not fetched or forwarded.
- Relative paths use the focused **local** terminal's working directory. From
  a remote space they use this computer's home, never the remote cwd.
- `~`, spaces and matching outer quotes work. Shell commands and variables
  are never expanded; filenames remain literal argv values.
- Common formats: MP4, M4V, MOV, MKV, WebM, AVI, OGV, MPEG, TS, FLV and WMV.
- URLs, playlists, non-regular files, files over 4 GiB, audio-only inputs, and
  video streams over 25 megapixels are rejected.
- `ffprobe` reads metadata with an eight-second timeout, file-only protocols,
  and a container whitelist. The player disables network protocols, reference
  loading, adjacent subtitle/audio files, YouTube handling and user scripts.
- User mpv configuration is disabled for predictable preview behavior. This
  mod supplies only the Escape-to-quit binding; normal playback keys remain.
- Nothing is copied into Herdr's asset directory, uploaded or saved as history.
  Startup diagnostics use a private temporary file, not persistent logs.

## Dependencies and helper

Python 3, **mpv**, and **ffprobe** must already be available on this computer.
They are present in the current development environment; this mod adds no
packages or executable to PATH. If Herdr cannot find them, check
`command -v mpv ffprobe` and quit/relaunch Herdr from a shell with that PATH.

Clipboard paths use `pbpaste`, `wl-paste` or `xclip`, with a one-second timeout.
Manual paste remains available when these utilities are missing.

```sh
herdr-app do mod.open:video-preview
python3 ~/.config/herdr-app/mods/video-preview/video.py ~/Videos/demo.mp4
python3 ~/.config/herdr-app/mods/video-preview/video.py --help
```

The bundled helper prints JSON and returns a nonzero status on validation or
immediate startup failure. `state: "launched"` means a player process survived
the short startup check, not proof that every frame will decode. Later playback
errors belong to the visible player. Videos start paused, so opening never
starts audio unexpectedly.

## Verify

```sh
python3 -m unittest discover -s nix/shared/herdr/tests -p test_video_preview.py
node --experimental-default-type=module --test nix/shared/herdr/tests/video-preview-view.test.mjs
herdr-app check ~/.config/herdr-app/mods/video-preview
```
