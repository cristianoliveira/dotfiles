{ pkgs, ... }:
let
  theme = import ./sddm-theme.nix { inherit pkgs; };
in {
  # SDDM on NixOS requires either X11 enabled or its own Wayland greeter enabled.
  # We keep greeter on X11 to avoid VT handoff issues with Sway sessions.
  services.xserver.enable = true;

  # Enable the gnome-keyring secrets vault. 
  # Will be exposed through DBus to programs willing to store secrets.
  services = {
    gnome.gnome-keyring.enable = true;
    displayManager = {
      defaultSession = "sway";

      sddm = {
        enable = true;
        theme = "${theme.theme}";

        # Wayland greeter caused VT handoff issues with Sway session:
        # first login bounced back to SDDM with
        # `Failed to take control of /dev/tty1`.
        # Keep SDDM on X11; user session still starts Sway.
        wayland.enable = false;
      };
    };
  };

  environment.systemPackages = theme.extraPackages; 
}
