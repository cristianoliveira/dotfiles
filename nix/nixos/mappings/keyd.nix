{ _, ... }: {

  ### Special Mappings
  #
  # Key bindings for the following changes:
  # - CapsLock is Control when held, Escape when tapped
  # - RightAlt + hjkl as arrow keys
  # - Option + aeiou for accents

  services = {
    keyd = {
      enable = true;

      keyboards = {
        default = {
          ids = [ "*" ];
          settings = {

            ## rightalt_hjkl layer
            # RightAlt + hjkl as arrow keys, fallback to Alt
            "rightalt_hjkl:G" = {
              h = "left";
              j = "down";
              k = "up";
              l = "right";
            };

            ## option_accents layer
            # Dead keys like in MacOS with option key 
            # Option + aeiou or falback to Super/Meta
            "option_accents:S" = {
              n = "macro(G-~)"; # tilde
              e = "macro(G-')"; # acute
              a = "macro(G-`)"; # grave
              i = "macro(G-6)"; # circumflex
              u = "macro(G-\")"; # diaeresis
            };

            main = {
              capslock = "overload(control, esc)";
              rightalt = "layer(rightalt_hjkl)";
              leftmeta = "layer(option_accents)";
            };
          };
        };
      };
    };


    # This didn't work, so check ../sway/config
    # xserver = {
    #   autoRepeatDelay = 1200;
    #   autoRepeatInterval = 20;
    #   xkb = {
    #     layout = "us";
    #     model = "pc104";
    #     variant = "altgr-intl";
    #     # FIXME this doesn't work. Bug on nix options, or overriden by xorg.conf?
    #     options = "altwin:swap_lalt_lwin";
    #   };
    # };

  };
}
