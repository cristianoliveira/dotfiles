{ _config, pkgs, _lib, ... }:
{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # so that gtk works properly
    extraPackages = with pkgs; [
      swaylock
      i3status
      swayidle

      autotiling

      # Keybindings daemon
      # NOTE try `sxhkd` to decouple keybindings from the window manager

      # Utilities
      wf-recorder
      grim # screenshot functionality
      slurp # screenshot functionality
      wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
      mako # notification system developed by swaywm maintainer
      wmctrl #https://github.com/Ulauncher/Ulauncher/wiki/Hotkey-In-Wayland

      # GUIs for common settings
      pavucontrol # audio manager

      # Launcher
      dmenu # Dmenu is the default in the config but i recommend wofi since its wayland native
      ulauncher

      # Displays UI manager
      wdisplays
    ];
  };

  ## This here isn't really necessary for the fix but let's ake sure
  # to explicitly enable and start the xdg-desktop-portal-* as services on login
  xdg.portal = {
    enable = true;

    # Expected by xdg-desktop-portal
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Allow applying the same settings to outside of X11
  console.useXkbConfig = true;

  ## Other related GUIS for settings
  # Bluetooth related 
  hardware.bluetooth = {
    enable = true;
  };

  # Enable sound with pipewire.
  # See: https://nixos.wiki/wiki/PipeWire
  # sound.enable = true;
  # hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
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
