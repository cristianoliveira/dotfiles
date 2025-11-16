{ pkgs, ... }: let 
  aerospaceNightly = pkgs.aerospace.overrideAttrs (_: finalAttrs: let 
      version = "0.19.1-Beta";
    in {
      inherit version;
      src = pkgs.fetchzip {
        url = "https://github.com/nikitabobko/AeroSpace/releases/download/v${version}/AeroSpace-v${version}.zip";
        sha256 = "sha256-9BR3dFqO1X35uyNcT5vgME0HqeHW/yo9qRIGZs2bvuA=";
      };
    });
in {
  environment.systemPackages = with pkgs; [
    # Requires custom packages
    copkgs.aerospace-marks
    copkgs.aerospace-scratchpad
  ];

  services = {
    aerospace = {
      enable = true;
      # Enable the aerospace service
      # This is a placeholder for the actual service
      # package = pkgs.aerospace;
      # NOTE: To install the latest version of Aerospace
      package = aerospaceNightly; 

      settings = {
        gaps = {
          inner.horizontal = 0;
          inner.vertical =   0;
          outer = {
            left =       0;
            bottom =     0;
            top =        0;
            right =      0;
          };
        };

        mode.main.binding = {
          alt-slash = "layout tiles horizontal vertical";
          alt-comma = "layout accordion horizontal vertical";
          alt-shift-enter = "layout tiling";

          # Fixed bindings
          ctrl-cmd-enter = "exec-and-forget open ~/Applications/Alacritty.app";
          ctrl-cmd-b = "exec-and-forget open '/Applications/Brave Browser.app'";

          # [Y]outube (focus)
          cmd-ctrl-y = ''
            exec-and-forget aerospace-marks focus "$(aerospace-marks get y -a)" \
                         || open -a YouTube.app && aerospace-marks mark y'';

          # See: https://nikitabobko.github.io/AeroSpace/commands#focus
          cmd-ctrl-h = "focus left";
          cmd-ctrl-j = "focus down";
          cmd-ctrl-k = "focus up";
          cmd-ctrl-l = "focus right";
          # Focus across all monitors
          cmd-ctrl-left = "focus left --boundaries all-monitors-outer-frame";
          cmd-ctrl-down = "focus down --boundaries all-monitors-outer-frame";
          cmd-ctrl-up = "focus up --boundaries all-monitors-outer-frame";
          cmd-ctrl-right = "focus right --boundaries all-monitors-outer-frame";

          # See: https://nikitabobko.github.io/AeroSpace/commands#move
          cmd-shift-h = "move left";
          cmd-shift-j = "move down";
          cmd-shift-k = "move up";
          cmd-shift-l = "move right";

          cmd-ctrl-shift-h = "move-node-to-monitor left --focus-follows-window";
          cmd-ctrl-shift-j = "move-node-to-monitor down --focus-follows-window";
          cmd-ctrl-shift-k = "move-node-to-monitor up --focus-follows-window";
          cmd-ctrl-shift-l = "move-node-to-monitor right --focus-follows-window";

          # Move the focused window with the same, but add Shift
          cmd-shift-left = "move left";
          cmd-shift-down = "move down";
          cmd-shift-up = "move up";
          cmd-shift-right = "move right";

          # See: https://nikitabobko.github.io/AeroSpace/commands#resize
          # cmd-minus = "resize smart -50";
          # cmd-equal = "resize smart +50";

          # See: https://nikitabobko.github.io/AeroSpace/commands#workspace
          cmd-1 = "workspace 1";
          cmd-2 = "workspace 2";
          cmd-3 = "workspace 3";
          cmd-4 = "workspace 4";
          cmd-5 = "workspace 5";
          cmd-6 = "workspace 6";
          cmd-7 = "workspace 7";
          cmd-8 = "workspace 8";
          cmd-9 = "workspace 9";
          cmd-0 = "workspace 0";

          # See: https://nikitabobko.github.io/AeroSpace/commands#move-node-to-workspace
          cmd-shift-1 = "move-node-to-workspace 1";
          cmd-shift-2 = "move-node-to-workspace 2";
          cmd-shift-3 = "move-node-to-workspace 3";
          cmd-shift-4 = "move-node-to-workspace 4";
          cmd-shift-5 = "move-node-to-workspace 5";
          cmd-shift-6 = "move-node-to-workspace 6";
          cmd-shift-7 = "move-node-to-workspace 7";
          cmd-shift-8 = "move-node-to-workspace 8";
          cmd-shift-9 = "move-node-to-workspace 9";
          cmd-shift-0 = "move-node-to-workspace 0";

          # cmd-backtick = "workspace-back-and-forth";

          cmd-ctrl-f = [
            "layout tiling"
            "fullscreen"
          ];
          # cmd-ctrl-space = "toggle float";

          ## Scratchpad workspace
          # This allows me to have a scratchpad workspace similart to i3
          # cmd-ctrl-backslash = "workspace scratchpad";
          cmd-m = "exec-and-forget aerospace-scratchpad move";
          cmd-ctrl-minus = "exec-and-forget aerospace-scratchpad next";

          # See: https://nikitabobko.github.io/AeroSpace/commands#layout
          cmd-ctrl-s = "layout v_accordion";
          cmd-ctrl-t = "layout h_accordion";

          cmd-h = []; # Disable "hide application"
          cmd-alt-h = []; # Disable "hide others"

          # Goto marks
          cmd-ctrl-g = "mode marks";
          cmd-g = "mode goto";

          # MOD+CTRL+m to set a mark
          cmd-ctrl-m = ''
            exec-and-forget aerospace-marks mark \
              $(osascript -e 'text returned of (display dialog "mark" default answer "")')
          '';
          # MOD+CTRL+' to focus a mark
          cmd-ctrl-quote = ''
            exec-and-forget aerospace-marks focus \
              $(osascript -e 'text returned of (display dialog "focus" default answer "")')
            '';
          # MOD+CTRL+;
          cmd-ctrl-semicolon = ''
            exec-and-forget aerospace-marks summon \
              $(osascript -e 'text returned of (display dialog "summon" default answer "")')
          '';

          cmd-f1 = "mode relocate";
          cmd-f2 = ''exec-and-forget ~/.dotfiles/bin/osx-win-resize \
              $(osascript -e \
                  'text returned of (display dialog "resize w%/h% (Eg. w50)" default answer "")')
          '';

          cmd-ctrl-o = "workspace-back-and-forth";

          ## SCRATCHPAD FIXED BINDINGS
          ## Things that I access less often ctrl-shift-cmd-<number>
          cmd-shift-ctrl-7 = ''
            exec-and-forget aerospace-scratchpad show Bitwarden \
                         || open -a Bitwarden'';
          cmd-shift-ctrl-8 = ''
            exec-and-forget aerospace-scratchpad show WhatsApp \
                        ||  open -a WhatsApp'';
          cmd-shift-ctrl-9 = ''
            exec-and-forget aerospace-scratchpad show Spotify \
                         || open -a Spotify'';

          ## Things that I access often ctrl-cmd-<number>
          cmd-ctrl-0 = ''
            exec-and-forget aerospace-scratchpad show Finder \
                         || open -a Finder'';

          # [N]ote taker
          cmd-ctrl-n = ''
            exec-and-forget aerospace-scratchpad show "$(aerospace-marks get n -a)" \
                        ||  aerospace-scratchpad show Obsidian \
                        ||  open -a Obsidian'';

          # Terminal s[c]rat[c]hpad
          ctrl-cmd-c = ''
            exec-and-forget aerospace-scratchpad show alacritty -F window-title='terminal-scratchpad' \
                         || alacritty -t 'terminal-scratchpad' --option window.opacity="0.9"
          '';

          # Specific marks
          # [Z]oom/Google Meet/Teams/Wire remote call tools
          cmd-ctrl-z = ''
            exec-and-forget aerospace-scratchpad show 'zoom.us|Meet|Teams' \
                         || aerospace-scratchpad show 'Google' -F window-title='Meet' \
                         || aerospace-scratchpad show 'Wire' -F window-title='Call'
          '';

          # Sequoia
          # SCRATCHPAD DYNAMIC BINDINGS
          # Left hand quick access
          cmd-ctrl-1 = [
            ''exec-and-forget aerospace-scratchpad show \
                            "$(aerospace-marks get 1 -a)"''
          ];
          cmd-ctrl-2 = [
            ''exec-and-forget aerospace-scratchpad show \
                            "$(aerospace-marks get 2 -a)"''
          ];
          cmd-ctrl-3 = [
            ''exec-and-forget aerospace-scratchpad show \
                            "$(aerospace-marks get 3 -a)"''
          ];
          cmd-ctrl-4 = [
            ''exec-and-forget aerospace-scratchpad show \
                            "$(aerospace-marks get 4 -a)"''
          ];
          cmd-ctrl-5 = [
            ''exec-and-forget aerospace-scratchpad show \
                            "$(aerospace-marks get 5 -a)"''
          ];

          # Right hand quick access
          cmd-ctrl-7 = [
            ''exec-and-forget aerospace-scratchpad show \
                            "$(aerospace-marks get 7 -a)"''
          ];
          cmd-ctrl-8 = [
            ''exec-and-forget aerospace-scratchpad show \
                            "$(aerospace-marks get 8 -a)"''
          ];
          cmd-ctrl-9 = [
            ''exec-and-forget aerospace-scratchpad show \
                            "$(aerospace-marks get 9 -a)"''
          ];
        };

        # Goto marks mode
        # cmd-g + <mark> to focus a mark
        mode.goto.binding = let
          h = [
            "exec-and-forget aerospace-marks focus h"
            "mode main"
          ];

          j = [
            "exec-and-forget aerospace-marks focus j"
            "mode main"
          ];

          k = [
            "exec-and-forget aerospace-marks focus k"
            "mode main"
          ];

          l = [
            "exec-and-forget aerospace-marks focus l"
            "mode main"
          ];

          f = [
            "exec-and-forget aerospace-marks focus f"
            "mode main"
          ];

          d = [
            "exec-and-forget aerospace-marks focus d"
            "mode main"
          ];

          s = [
            "exec-and-forget aerospace-marks focus s"
            "mode main"
          ];

          a = [
            "exec-and-forget aerospace-marks focus a"
            "mode main"
          ];

          g = [
            "exec-and-forget aerospace-marks focus g"
            "mode main"
          ];
        in {
          esc = "mode main";
          enter = "mode main";
          cmd-space = "mode main";

          inherit h;
          cmd-h = h;
          inherit j;
          cmd-j = j;
          inherit k;
          cmd-k = k;
          inherit l;
          cmd-l = l;
          inherit f;
          cmd-f = f;
          inherit d;
          cmd-d = d;
          inherit s;
          cmd-s = s;
          inherit a;
          cmd-a = a;
          inherit g;
          cmd-g = g;
        };

        mode.relocate.binding = {
          esc = "mode main";
          enter = "mode main";

          u = [
            "exec-and-forget ~/.dotfiles/bin/osx-win-move topleft"
            "mode main"
          ];
          i = [
            "exec-and-forget ~/.dotfiles/bin/osx-win-move center"
            "mode main"
          ];
          o = [
            "exec-and-forget ~/.dotfiles/bin/osx-win-move topright"
            "mode main"
          ];
          j = [
            "exec-and-forget ~/.dotfiles/bin/osx-win-move bottomleft"
            "mode main"
          ];
          k = [
            "exec-and-forget ~/.dotfiles/bin/osx-win-move bottomcenter"
            "mode main"
          ];
          l = [
            "exec-and-forget ~/.dotfiles/bin/osx-win-move bottomright"
            "mode main"
          ];
        };

        mode.resize.binding = {
          esc = "mode main";
          enter = "mode main";

          u = [
            "exec-and-forget ~/.dotfiles/bin/osx-win-resize w1/2"
            "mode main"
          ];
          i = [
            "exec-and-forget ~/.dotfiles/bin/osx-win-resize w1/3"
            "mode main"
          ];
          o = [
            "exec-and-forget ~/.dotfiles/bin/osx-win-resize w1/4"
            "mode main"
          ];
          j = [
            "exec-and-forget ~/.dotfiles/bin/osx-win-resize h1/2"
            "mode main"
          ];
          k = [
            "exec-and-forget ~/.dotfiles/bin/osx-win-resize h1/3"
            "mode main"
          ];
          l = [
            "exec-and-forget ~/.dotfiles/bin/osx-win-resize h1/4"
            "mode main"
          ];
        };

        exec.env-vars = {
          AEROSPACE_SCRATCHPAD_LOGS_LEVEL = "DEBUG";
          AEROSPACE_MARKS_LOGS_LEVEL = "DEBUG";
          
          PATH = "\${HOME}/golang/bin:/opt/homebrew/bin:/run/current-system/sw/bin:\${PATH}";
        };

        workspace-to-monitor-force-assignment = {
          "1" = "main";
          "2" = "main";
          "3" = "main";
          "4" = "main";
          "5" = "main";
          "6" = ["secondary" "main" "built-in"];
          "7" = ["secondary" "main" "built-in"];
          "8" = ["secondary" "main" "built-in"];
          "9" = ["built-in" "main"];
          "0" = ["built-in" "main"];
          # ".scratchpad" = "main";
        };

        on-window-detected = [
          {
            "if".app-name-regex-substring = "alacritty|terminal";
            run = [ "move-node-to-workspace 2" ];
          }
          {
            "if".app-name-regex-substring = "YouTube";
            run = [ "move-node-to-workspace 8" ];
          }
          {
            "if".app-name-regex-substring = 
              "ChatGPT|Clock|WhatsApp|Spotify|Slack|Telegram|Google.Meet|Zoom|Teams|Finder|Wire";
            run = [
              "layout floating"
            ]; 
          }
          {
            "if".app-name-regex-substring = "Brave";
            run = [
              "move-node-to-workspace 1"
            ]; 
          }
          {
            "if".app-name-regex-substring = "Picture.*Picture"; 
            run = [ "layout floating" ];
          }

          # Ensure all windows on workspace 2 (the workspace where contains the terminal)
          # are in h_accordion layout, so it is presented like a fullscreen transparent terminal 
          # and the other apps behind it
          # {
          #   "if".workspace = "2";
          #   run = [ "layout h_accordion" ];
          # }
        ];

        on-focused-monitor-changed = [
          "exec-and-forget aerospace-scratchpad wsh bring-scratchpad-to-monitor 0 0"
        ];

        # Makes accordion layout like fullscreen
        accordion-padding = 1;

        # setting.end
      };
    };
  };
}

