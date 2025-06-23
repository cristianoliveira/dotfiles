{ pkgs, ... }: 

{
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
      package = pkgs.aerospace;

      settings = {
        gaps = {
          inner.horizontal = 0;
          inner.vertical =   0;
          outer.left =       0;
          outer.bottom =     0;
          outer.top =        0;
          outer.right =      0;
        };

        mode.main.binding = {
          alt-slash = "layout tiles horizontal vertical";
          alt-comma = "layout accordion horizontal vertical";
          alt-shift-enter = "layout tiling";

          # Fixed bindings
          ctrl-cmd-enter = "exec-and-forget open ~/Applications/Alacritty.app";
          ctrl-cmd-b = "exec-and-forget open '/Applications/Brave Browser.app'";

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

          cmd-ctrl-m = ''
            exec-and-forget aerospace-marks mark \
              $(osascript -e 'text returned of (display dialog "mark" default answer "")')
          '';
          cmd-ctrl-quote = ''
            exec-and-forget aerospace-marks focus \
              $(osascript -e 'text returned of (display dialog "focus" default answer "")')
            '';
          cmd-ctrl-slash = ''
            exec-and-forget aerospace-marks summon \
              $(osascript -e 'text returned of (display dialog "summon" default answer "")')
          '';

          cmd-f1 = "mode relocate";
          cmd-f2 = ''exec-and-forget ~/.dotfiles/bin/osx-win-resize \
              $(osascript -e \
                  'text returned of (display dialog "resize w%/h% (Eg. w50)" default answer "")')
          '';

          cmd-ctrl-0 = "exec-and-forget aerospace-scratchpad show Finder";
          cmd-ctrl-9 = "exec-and-forget aerospace-scratchpad show Bitwarden";
          cmd-ctrl-8 = "exec-and-forget aerospace-scratchpad show WhatsApp";
          cmd-ctrl-7 = "exec-and-forget aerospace-scratchpad show Spotify";

          # TODO adds a way to center a window with move/resize mode
          # TODO adds a way to center-left/right a window with move/resize mode

          cmd-ctrl-o = "workspace-back-and-forth";

          # Specific marks
          # Zoom/Google Meet/Teams remote call tool
          cmd-ctrl-z = 
            "exec-and-forget aerospace-scratchpad show 'zoom.us|Google.Meet|Teams'";

          cmd-ctrl-n = [
            ''exec-and-forget aerospace-scratchpad show "$(aerospace-marks get n -a)" \
                          || aerospace-scratchpad show Obsidian
            ''
          ];

          # Quick generic marks
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

          h = h;
          cmd-h = h;
          j = j;
          cmd-j = j;
          k = k;
          cmd-k = k;
          l = l;
          cmd-l = l;
          f = f;
          cmd-f = f;
          d = d;
          cmd-d = d;
          s = s;
          cmd-s = s;
          a = a;
          cmd-a = a;
          g = g;
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
          
          PATH = "/opt/homebrew/bin:\${HOME}/golang/bin:/run/current-system/sw/bin:\${PATH}";
        };

        workspace-to-monitor-force-assignment = {
          "1" = "main";
          "2" = "main";
          "3" = "main";
          "4" = "main";
          "5" = "main";
          "6" = ["secondary" "main"];
          "7" = ["secondary" "main"];
          "8" = ["secondary" "main"];
          "9" = ["built-in" "main"];
          "0" = ["built-in" "main"];
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
              "ChatGPT|Clock|WhatsApp|Spotify|Slack|Telegram|Google.Meet|Zoom|Teams|Finder";
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
        ];

        # Makes accordion layout like fullscreen
        accordion-padding = 1;

        # setting.end
      };
    };
  };
}
