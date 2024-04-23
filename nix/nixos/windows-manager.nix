{ config, pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    # Windows manager
    sway
  ];
  
  services.gnome.gnome-keyring.enable = true;

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # so that gtk works properly
    extraPackages = with pkgs; [
      swaylock
      i3status
      swayidle

      # Utilities
      wf-recorder
      mako # notification daemon
      grim # screenshot functionality
      slurp # screenshot functionality
      wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
      mako # notification system developed by swaywm maintainer
      wmctrl #https://github.com/Ulauncher/Ulauncher/wiki/Hotkey-In-Wayland

      # GUIs for common settings
      blueman # bluetooth manager
      pavucontrol # audio manager

      # Launcher
      dmenu # Dmenu is the default in the config but i recommend wofi since its wayland native
      ulauncher

    ];
  };

  services.xserver = {
    # Enable the X11 windowing system.
    enable = true;
    displayManager.sddm.enable = true;

    # Configure keymap in X11
    # Didn't manage to use nix to configure this
    # Check ~/.config/sway/config

    # layout = "us";
    # xkbVariant = "altgr-intl";
    # xkbOptions = "caps:ctrl_modifier,altwin:swap_lalt_lwin";
    # Keyboard repeat rate
    # autoRepeatDelay = 100;
    # autoRepeatInterval = 10;

    # Enable touchpad support (enabled default in most desktopManager).
    # libinput.enable = true;

    # Enable the Desktop manager for logins
    # exportConfiguration = true;
  };

  # Allow applying the same settings to outside of X11
  console.useXkbConfig = true;
}
