{ config, pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    # Windows manager
    sway
  ];
  
  # Enable the gnome-keyring secrets vault. 
  # Will be exposed through DBus to programs willing to store secrets.
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

  services.displayManager.sddm.enable = true;

  services.xserver = {
    # Enable the X11 windowing system.
    enable = true;

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

  ## Other related GUIS for settings
  # Bluetooth related 
  hardware.bluetooth = {
    enable = true;
  };
  services.blueman = {
    enable = true;
  };

  # Enable sound with pipewire.
  sound.enable = true;
  security.rtkit.enable = true;

  # Need to be false because of pipeware
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

}
