{ pkgs, ... }:
  let 
    webapps = import ../shared/webapps.nix { inherit pkgs; };
  in {
    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    environment.systemPackages = with pkgs; [
      alacritty 

      # FIXME this package is failing
      # bitwarden-cli

      # OSX tiling window manager
      # yabai
      # skhd

      webapps.chatgpt
      webapps.youtube
    ];
  }
