{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.tailscale ];
}
