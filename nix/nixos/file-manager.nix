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

    xfconf.enable = true;
  };

  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images

  environment.systemPackages = with pkgs; [
    file-roller # Archive manager (programs.file-roller was removed in 26.05)
  ];

  environment.sessionVariables = {
    GTK_THEME = "Adwaita:dark";
  };
# .thunar .sidebar GTK_THEME
}
