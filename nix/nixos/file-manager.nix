
{ config, pkgs, lib, ... }:
{
  # Dolphin file manager
  # https://wiki.nixos.org/wiki/Dolphin
  environment.systemPackages = with pkgs; [
    kdePackages.dolphin
    kdePackages.qtwayland
    kdePackages.qt6ct
    kdePackages.qtsvg
  ];
}
