{ pkgs, ... }:
{
  # environment.systemPackages = [
  #   pkgs.openvpn 
  #   pkgs.openresolv
  # ];
  
  environment.systemPackages = [ 
    pkgs.mullvad-vpn
    pkgs.mullvad

    ##TODO move it
    pkgs.rustdesk
  ];
  services.mullvad-vpn.enable = false;
}
