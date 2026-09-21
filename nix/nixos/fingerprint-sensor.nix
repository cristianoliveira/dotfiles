_:
{
  # NOTE: It is working on ThinkPad P14s Gen 5
  # See more: https://archive.is/tYQlZ
  # This config allow authentication with fingerprint on SDDM, swaylock and on
  # the terminal.

  # Start the daemon before the display manager so fingerprint auth is ready
  # when SDDM shows the login screen.
  systemd.services.fprintd = {
    wantedBy = [ "graphical.target" ];
    before = [ "display-manager.service" ];
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  # Install the driver
  services.fprintd = { 
    enable = true;
    # If simply enabling fprintd is not enough, try enabling fprintd.tod...
    # tod.enable = true;
    # ...and use one of the next four drivers
    # tod.driver = pkgs.libfprint-2-tod1-goodix;
  };

  security.pam.services = {
    login.fprintAuth = true;
    swaylock.fprintAuth = true;
    sddm.fprintAuth = true;
  };
}
