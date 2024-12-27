{ _ , ... }:
{
  # NOTE: It is working on ThinkPad P14s Gen 5
  # See more: https://archive.is/tYQlZ
  # This config allow authentication with fingerprint on SDDM, swaylock and on
  # the terminal.

  # Start the driver at boot
  systemd.services.fprintd = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "simple";
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
    # sddm.enableGnomeKeyring = true;

    login.fprintAuth = true;

    # Requires attempting to login with an empty password first so PAM will ask for the fingerprint
    # See https://github.com/swaywm/swaylock/issues/61
    swaylock.text = ''
      auth sufficient pam_unix.so try_first_pass likeauth nullok
      auth sufficient pam_fprintd.so
      auth include login
    '';

    # Similar flow required here: Enter a blank password first, then use the fingerprint
    sddm.text = ''
      auth [success=1 new_authtok_reqd=1 default=ignore] pam_unix.so try_first_pass likeauth nullok
      auth sufficient pam_fprintd.so
    '';
  };
}
