{ config, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.mullvad-vpn pkgs.mullvad ];
  services.mullvad-vpn.enable = true;
}
