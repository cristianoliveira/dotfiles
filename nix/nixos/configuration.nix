# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # NixOs specific configurations
      ./windows-manager.nix
      ./display-manager.nix
      ./mappings/keyd.nix
      ./file-manager.nix
      ./applications.nix
      ./streaming.nix
      ./fingerprint-sensor.nix
      ./gaming.nix
      ./utils.nix
      ./file-sync.nix

      # Shared configurations
      ../shared/direnv.nix
      ../shared/developer-tools.nix
      ../shared/environment-variables.nix
      ../shared/stow.nix
    ];

  hardware.graphics.enable = true;

  # services.printing.enable = true;
  hardware.printers = {
    ensurePrinters = [
      {
        name = "MG2500-series";
        location = "Home";
        deviceUri = "https://printers.nixpi.lab/printers/MG2500-series";
        model = "drv:///sample.drv/generic.ppd";
        ppdOptions = {
          ColorModel = "RGB";
          PageSize = "A4";
        };
      }
      # Black and white printer
      {
        name = "MG2500-series-bw";
        location = "Home";
        deviceUri = "https://printers.nixpi.lab/printers/MG2500-series";
        model = "drv:///sample.drv/generic.ppd";
        ppdOptions = {
          ColorModel = "KGray"; # RGB CMYGray KGray
          PageSize = "A4";
        };
      } 
    ];
    ensureDefaultPrinter = "MG2500-series";
  };

  # To enable scanner
  # hardware.sane.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
    extraGroups = [ 
      "networkmanager" 
      "wheel"
      "docker" 
      # Required for screen brightness (see programs.light)
      "video"
      "scanner"
      "lp" 
    ];
  };

  # Enable light for screen brightness
  # Need to add user to "video" group See above
  programs.light.enable = true;

  virtualisation.docker.enable = true;

  nixpkgs.config.allowUnfree = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };


  # Screen brightness and back linght management
  programs = {
    # This enables running unpatched binaries from Nix store
    # which is necessary for Mason (nvim) to work
    # see also the environment variable NIX_LD below
    #
    # Detailed explanation: http://archive.today/WFxH7
    nix-ld.enable = true;

    zsh = {
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
      '';
    };
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
  system.stateVersion = "24.05"; # Did you read the comment?

  # Experimental features
  # If you used nix/nixos/setup.sh to setup your system this feature is already enabled
  # via the $HOME/.config/nix/nix.conf file
  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];

    # Enable garbage collection every day at 22:00 and delete older than 14 days
    gc = {
      automatic = true;
      dates = "22:00";
      options = "--delete-older-than 14d";
    };
  };
}
