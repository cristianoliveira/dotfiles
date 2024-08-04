{ config, pkgs, lib, ... }:
{
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
  ];
}
