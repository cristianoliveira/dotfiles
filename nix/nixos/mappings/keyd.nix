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
            # RightAlt + hjkl as arrow keys, fallback to Windows key (Meta)
            "rightalt_hjkl:M" = {
              h = "left";
              j = "down";
              k = "up";
              l = "right";

              # Mimic ctrl + ud or gg
              u = "pageup";
              d = "pagedown";
            };

            #### NOTE: This is not being used but will leave as example 
            # option_accents layer
            # Dead keys like in MacOS with option key 
            # Option + aeiou or falback to Super/Meta
            "option_accents:S" = {
              n = "macro(G-~)"; # tilde
              e = "macro(G-')"; # acute
              a = "macro(G-`)"; # grave
              i = "macro(G-6)"; # circumflex
              u = "macro(G-\")"; # diaeresis
              c = "macro(G-,)"; # cedilla
            };

            main = {
              capslock = "overload(control, esc)";
              rightalt = "layer(rightalt_hjkl)";
              # leftmeta = "layer(option_accents)";
            };
          };
        };
      };
    };
  };
}
