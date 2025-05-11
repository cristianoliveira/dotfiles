{ pkgs, ... }: 

{
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

          ctrl-cmd-enter = [
            "focus-back-and-forth" # Workaround for when the workspace is empty
            "exec-and-forget open -a ~/Applications/Alacritty.app"
          ];

          # See: https://nikitabobko.github.io/AeroSpace/commands#focus
          cmd-ctrl-h = "focus left";
          cmd-ctrl-j = "focus down";
          cmd-ctrl-k = "focus up";
          cmd-ctrl-l = "focus right";

          # See: https://nikitabobko.github.io/AeroSpace/commands#move
          cmd-shift-h = "move left";
          cmd-shift-j = "move down";
          cmd-shift-k = "move up";
          cmd-shift-l = "move right";

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

          cmd-backtick = "workspace-back-and-forth";

          cmd-ctrl-f = "fullscreen";
          # cmd-ctrl-space = "toggle float";

          ## Scratchpad workspace
          # This allows me to have a scratchpad workspace similart to i3
          # cmd-ctrl-backslash = "workspace scratchpad";
          cmd-m = "move-node-to-workspace scratchpad";
          cmd-ctrl-slash = "workspace scratchpad";
          cmd-shift-minus = "move-node-to-workspace scratchpad";
          cmd-minus = [
            "exec-and-forget aerospace focus --window-id $(aerospace list-windows --workspace 2 | grep -v \"$(aerospace list-windows --focused | awk '{print $1}')\" | awk '{print $1}')"
            "focus left"
          ];

          # See: https://nikitabobko.github.io/AeroSpace/commands#layout
          cmd-ctrl-s = "layout v_accordion";
          cmd-ctrl-t = "layout h_accordion";

          cmd-h = []; # Disable "hide application"
          cmd-alt-h = []; # Disable "hide others"
        };

        workspace-to-monitor-force-assignment = {
          "1" = "main";
          "2" = "main";
          "3" = "main";
          "4" = "main";
          "5" = "main";
          "7" = ["secondary" "main"];
          "8" = ["secondary" "main"];
          "9" = ["secondary" "main"];
          "0" = ["secondary" "main"];
        };

        on-window-detected = [
          {
            "if".app-name-regex-substring = "alacritty|terminal";
            run = [ "move-node-to-workspace 2" ];
          }
          {
            "if".app-name-regex-substring = "ChatGPT";
            run = [ "move-node-to-workspace 4" ];
          }
          {
            "if".app-name-regex-substring = "YouTube";
            run = [ "move-node-to-workspace 7" ];
          }
          {
            "if".app-name-regex-substring = "WhatsApp|Spotify|Slack";
            run = [ "move-node-to-workspace scratchpad" ]; 
          }
        ];

        # Makes accordion layout like fullscreen
        accordion-padding = 1;

        # setting.end
      };
    };
  };
}
