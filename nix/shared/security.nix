# Security related packages
# FIXME this module isn't working as expected
# there is an issue with pinentry
{ pkgs, ... }: {

  # To generate GPG keys
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    # pinentryFlavor = "gtk2";
    pinentryPackage = pkgs.pinentry;
  };
}
