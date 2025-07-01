{ pkgs, ... }:

{
  programs = {
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };

    file-roller.enable = true; # Archive manager for Thunar

    xfconf.enable = true;
  };

  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images

  environment.sessionVariables = {
    GTK_THEME = "Adwaita:dark";
  };
# .thunar .sidebar GTK_THEME
}
