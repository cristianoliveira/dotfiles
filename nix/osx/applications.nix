{ pkgs, ... }: {
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    alacritty

    # FIXME this package is failing
    # bitwarden-cli

    obsidian

    # webapps.chatgpt doesn't work in macOS
    # webapps.youtube
  ];

  # GUI applications via homebrew
  homebrew = {
    # FIXME: homebrew got screwed up after upgrading. Need to debug
    enable = false;

    taps = [];

    casks = [
      "alfred" # Launcher

      # Browsers
      # "firefox"
      "google-chrome"
      # "google-chrome-canary"
      "brave-browser"
      "finicky" # Ensure to open links in a browser/profile based on rules

      # Entertainment Apps
      "spotify"
      "slack"
      "whatsapp"
      "telegram"

      "karabiner-elements"

      # Others
      "bitwarden"
      # "veracrypt"
      # "mullvadvpn"
      # "tunnelblick" # VPN
      "google-drive"

      "superproductivity" # Task management / Pomodoro timer
    ];
  };
}
