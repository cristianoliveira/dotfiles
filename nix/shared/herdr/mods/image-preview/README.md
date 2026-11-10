# Image preview

Open a PNG or JPEG in a separate popup that fills Herdr's window. The complete
image fits without cropping or changing the source terminal. This does not
change the operating system's fullscreen setting.

## Use

1. Copy the image's **file path**, not the image itself.
2. Press **Ctrl-Shift-i**. **Ctrl-a**, release Ctrl, then **i** also works.
3. The popup reads the copied path and opens it on the focused space's machine.
   If no path was copied, paste one into the field and press Enter.
4. The controls hide after loading so the image uses the full window. Press
   **E** or click Edit to show the path and machine controls again.
5. Choose a machine with the buttons or **Alt-m**, then press Enter to reload.
6. Press **Esc** or click Close to leave.

You can also drop an image file onto the open popup. Dropped desktop files
always open on `local`, even if the original space is remote.

From a terminal, run `herdr-app do mod.open:image-preview`.

Herdr does not expose images already rendered inside a terminal. This mod
needs their file paths; it cannot detect the last image an agent read. It does
not send keys or scroll events to the source terminal.

## Paths and limits

- The machine defaults to the focused space. Select `local` for a local file.
- Relative paths initially use the focused terminal's working directory. After
  switching machines, they use that machine's active space folder, or its home.
- `~` and quoted paths work. Shell variables and commands are never expanded.
- Supported formats: PNG and JPEG. URLs and SVG are rejected.
- Maximum file size: 16 MiB. Maximum dimensions: 25 megapixels.
- Python 3 is required locally and on remote machines. Remote reads use
  `hc exec` with six-second execution and eight-second client timeouts; no
  remote mod installation is needed.
- Clipboard text is read using `pbpaste`, `wl-paste`, or `xclip`, with a one-second
  timeout. If no clipboard tool works, manual paste remains available. No host
  clipboard capability is added.

## Local assets

The native image renderer needs assets under Herdr's app directory. The helper
stages images in `~/.config/herdr-app/image-previews/`, not in this mod's source
folder. The directory is private (0700), and files are private (0600).

The cache keeps at most eight images. Assets older than one day are removed on
the next successful preview. Cleanup requires this mod's ownership marker and
only removes its own regular, content-addressed asset names; unrelated files
and symlinks are left alone. Preview files can remain until another image is
opened. Nothing is uploaded to an external service.

## Verify

```sh
python3 -m unittest discover -s nix/shared/herdr/tests -p test_image_preview.py
node --experimental-default-type=module --test nix/shared/herdr/tests/image-preview*.test.mjs
herdr-app check ~/.config/herdr-app/mods/image-preview
```
