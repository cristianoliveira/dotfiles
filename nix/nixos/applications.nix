{ pkgs, ... }: let
  webapps = import ../shared/webapps.nix { inherit pkgs; };
in {
  # Applications here more GUIs apps that are commonly used

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # GUIs
    alacritty
    bitwarden

    ## Media manipulation
    gimp

    # Data managment
    rclone
    zip
    unzip

    # Notes and organization tools
    obsidian

    # Browsers
    firefox
    brave

    # Music
    spotify

    # Communication apps
    zapzap
    telegram-desktop


    # Web apps
    webapps.googlekeep
    webapps.chatgpt
    webapps.youtube
    webapps.discord
  ];
}
