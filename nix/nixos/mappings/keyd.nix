{ _, ... }: {
# See 
# Key bindings for the following changes:
# - CapsLock is Control when held, Escape when tapped
  services = {
    keyd = {
      enable = true;

      keyboards = {
        default = {
          ids = [ "*" ];
          settings = {
            main = {
              capslock = "overload(control, esc)";
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
