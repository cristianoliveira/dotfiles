{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.tailscale
    pkgs.tailscale-gui
  ];
}
