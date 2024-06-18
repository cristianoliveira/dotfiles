# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./essential-pkgs.nix
      ./mappings/dual-keys.nix
      ./windows-manager.nix
      ./vpn.nix
      ../shared/direnv.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  # To connect to wifi run: nmtui
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


  # Enables running unpatched binaries from Nix store
  # This is necessary for Mason (nvim) to work
  # see also the environment variable NIX_LD below
  #
  # Detailed explanation:
  # https://web.archive.org/web/20240324024149/https://blog.thalheim.io/2022/12/31/nix-ld-a-clean-solution-for-issues-with-pre-compiled-executables-on-nixos/
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
