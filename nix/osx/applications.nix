{ pkgs, ... }: {
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    unstable.alacritty

    # FIXME this package is failing
    # bitwarden-cli

    obsidian

    # webapps.chatgpt doesn't work in macOS
    # webapps.youtube
  ];

  # GUI applications via homebrew
  homebrew = {
    # Cask activation fails on existing /Applications app permissions.
    enable = false;

    taps = [];

    casks = [
      "alfred" # Launcher

      # Browsers
      # "firefox"
      "google-chrome"
      # "google-chrome-canary"
      "brave-browser"

      # Entertainment Apps
      "spotify"
      "slack"
      "whatsapp"
      "telegram"

      "karabiner-elements"
      "handy"

      # Others
      "bitwarden"
      "rustdesk"
      # "veracrypt"
      # "mullvadvpn"
      # "tunnelblick" # VPN
      "google-drive"
    ];
  };
}
