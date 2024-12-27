{ pkgs, ... }:
let
  theme = import ./sddm-theme.nix { inherit pkgs; };
in {
  # Enable the gnome-keyring secrets vault. 
  # Will be exposed through DBus to programs willing to store secrets.
  services = {
    gnome.gnome-keyring.enable = true;
    displayManager = { 
      sddm = {
        enable = true;
        theme = "${theme.theme}";

        wayland.enable = true;
      };
    };
  };

  environment.systemPackages = theme.extraPackages; 
}
