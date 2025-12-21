# Window manager parity notes (macOS Aerospace ↔ NixOS sway)

Purpose: how to mirror the macOS Aerospace workspace/output/app rules into `nix/nixos/sway/config`.

## Outputs and workspace placement
- macOS names: `main` (DP-10), `secondary` (DP-9), `built-in` (eDP-1). In sway: `set $main DP-10`, `set $2nd DP-9`, `set $builtin eDP-1`.
- Aerospace `workspace-to-monitor-force-assignment`: 1–5 → main; 6–8 → secondary (fallback built-in/main); 9/0 → built-in. Sway cannot express fallbacks; use `workspace N output $name` with this priority.

## App → workspace rules
- Terminals: `assign [app_id=$termMain] workspace 2` and `assign [app_id="(?i)(alacritty|terminal)"] workspace 2`.
- Browsers: `assign [class="Brave-browser"] workspace 1` and `assign [app_id="brave-browser"] workspace 1`.
- YouTube: send to workspace 8 with broad matches:
  - `assign [instance=".*.youtube.com"] workspace 8`
  - `assign [app_id="brave-www.youtube.com__-Default"] workspace 8`
  - `assign [app_id="brave-.*youtube.*"] workspace 8`
  - `assign [class="Brave-browser" title=".*YouTube.*"] workspace 8`
  - `assign [app_id="brave-browser" title=".*YouTube.*"] workspace 8`
  - `assign [title=".*YouTube.*"] workspace 8`
  - Move-if-missed: `for_window [...] move container to workspace number 8` for the same matchers.

## Marks and focus helpers
- Mark YouTube windows for quick focus: `for_window` rules marking `y` for the YouTube matchers above.
- Keybinding: `bindsym $mod+Ctrl+y` tries `con_mark="y"`, then YouTube matchers, else runs `exec youtube`.

## Layout defaults
- Mimic Aerospace accordion: enforce tabbed on workspaces 2 and 8 with `for_window [workspace="2"] layout tabbed` and `for_window [workspace="8"] layout tabbed`.

## Keybindings / mappings parity
- Aerospace “modes” (jump marks, relocate, resize) map to sway `mode {}` blocks with `bindsym`. Mirror the intent, not the literal keys (cmd/ctrl vs `$mod`); keep ergonomic positions consistent.
- Marks: Aerospace uses `aerospace-marks mark/focus`. In sway, use `for_window … mark "<id>"` for auto-marks and `bindsym $mod+Ctrl+<key> exec swaymsg [con_mark="<id>"] focus` for recall.
- Scratchpad: Aerospace scratchpad hooks are approximated via sway’s native scratchpad (`move to scratchpad` + `scratchpad show`) and optional helper scripts; there is no 1:1 `exec-on-workspace-change` hook.
- Layout hotkeys: Aerospace uses `cmd-ctrl-s/t` for v/h accordion. In sway, map to `bindsym $mod+Ctrl+s layout tabbed` and `bindsym $mod+Ctrl+t layout stacking` (or a custom script) because sway has tabbed/stacked instead of accordion.
- Relocate/resize modes: Aerospace `mode relocate` (u/i/o/j/k/l for window positions) and `mode resize` (u/i/o/j/k/l for fractional resize) can be mirrored with sway `mode relocate { bindsym u move position … }` and `mode resize { bindsym u resize set width 50ppt … }` if parity is desired; not present by default.
- Scratchpad quick slots: Aerospace uses `cmd-ctrl-[1-9,0]` to show marks from scratchpad. Sway equivalent would be `bindsym $mod+Ctrl+<n> exec swaymsg [con_mark="<n>"] scratchpad show || <launch>`; currently not mirrored.
- Dialog-based marks (Aerospace cmd-ctrl-m/quote/semicolon prompts) are not mirrored; sway uses fixed-mark keybindings instead.
- Workspace back/forth: Aerospace `cmd-ctrl-o` is mirrored as `bindsym $mod+Ctrl+o workspace back_and_forth` (plus the existing `$mod+grave`).
- Jump mode: Aerospace `mode.jump` to focus marks is mirrored by sway `mode "goto"` bound to `$mod+apostrophe` (matching cmd-quote), covering digits and the QWERTY rows plus home row (`1-0, qwertyuiop, asdfghjkl, zxcvbn, t,y`).

## Floating utility apps (partial parity)
- Float comm/utility apps: `for_window [class="^(ChatGPT|Clock|WhatsApp|Spotify|Slack|Telegram|Google\\.Meet|Zoom|Teams|Finder|Wire)$"] floating enable`.
- macOS also floats Picture-in-Picture; add `for_window [title="^.icture.in..icture$"] floating enable, move position 74ppt 74ppt, sticky enable` if needed.

## Scratchpads (sway-only)
- Keep scratchpad rules for ZapZap/Telegram/Spotify/Bitwarden/Obsidian/Thunar as in `nix/nixos/sway/config`; Aerospace uses a different hook and cannot be mirrored directly.

## Testing and IPC
- Reload after changes: `swaymsg reload`.
- Inspect matches: `swaymsg -t get_tree | jq '..|objects|select(.app_id? // .class? // .instance?)|{app_id,class,instance,title,workspace}'`.
- If `swaymsg` fails, ensure `SWAYSOCK` points to the active socket under `/run/user/$UID/` (e.g., `export SWAYSOCK=/run/user/1000/sway-ipc.1000.<pid>.sock`).
