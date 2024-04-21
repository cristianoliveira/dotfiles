# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./essential-pckgs.nix
      ./mappings/xserver.nix
      ./mappings/dual-keys.nix
      ./windows-manager.nix
      ../shared/direnv.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.cristianoliveira = {
    isNormalUser = true;
    description = "cristianoliveira";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      firefox
      brave

      spotify
      whatsapp-for-linux
      telegram-desktop

    ];
  };

  virtualisation.docker.enable = true;

  nixpkgs.config.allowUnfree = true;

  # Enable the wakeup on USB feature
  # TODO check if this is working properly, just committing to avoid losing the config
  powerManagement = {
    enable = true;
    powerDownCommands = ''
    echo enabled > /sys/bus/usb/devices/usb1/power/wakeup
    echo enabled > /sys/bus/usb/devices/usb2/power/wakeup
    echo enabled > /sys/bus/usb/devices/usb3/power/wakeup
    echo enabled > /sys/bus/usb/devices/usb4/power/wakeup
    echo enabled > /sys/bus/usb/devices/usb5/power/wakeup
    echo enabled > /sys/bus/usb/devices/usb6/power/wakeup
    echo enabled > /sys/bus/usb/devices/usb7/power/wakeup
    echo enabled > /sys/bus/usb/devices/usb8/power/wakeup
    '';
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };


  # Enable the gnome-keyring secrets vault. 
  # Will be exposed through DBus to programs willing to store secrets.
  services.gnome.gnome-keyring.enable = true;

  # Enables running unpatched binaries from nix store
  # this is necessary for Mason (nvim) to work
  # see also NIX_LD environment variable below below
  programs.nix-ld = {
    enable = true;
  };

  programs.zsh = {
    enable = true;
    ohMyZsh = {
        enable = true;
	theme = "clean";
        plugins = ["git" "history-substring-search" "vi-mode"];
    };    

    interactiveShellInit = ''
      autoload -U +X compinit && compinit
      export NIX_ENV=1

      export NIX_LD=$(nix eval --extra-experimental-features nix-command --impure --raw --expr 'let pkgs = import <nixpkgs> {}; NIX_LD = pkgs.lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker"; in NIX_LD')

      export PATH=$HOME/.npm-global/bin:/usr/local/bin:$PATH
    '';
  };

  users.users.cristianoliveira.shell = pkgs.zsh;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  # Experimental features
  # If you used nix/nixos/setup.sh to setup your system this feature is already enabled
  # via the $HOME/.config/nix/nix.conf file
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
