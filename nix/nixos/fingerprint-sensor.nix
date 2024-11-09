{ pkgs ? import <nixpkgs> {} }:
{
  # NOTE: tested and it works on ThinkPad T14 Gen 5
  # need to integrate with PAM to work with login screen
  # See more: https://archive.is/tYQlZ

  # Start the driver at boot
  systemd.services.fprintd = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "simple";
  };

  # Install the driver
  services.fprintd.enable = true;
  # If simply enabling fprintd is not enough, try enabling fprintd.tod...
  services.fprintd.tod.enable = true;
  # ...and use one of the next four drivers
  services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;
}
