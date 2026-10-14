{ config, pkgs ? import <nixpkgs> {}, ... }: {
  environment.systemPackages = with pkgs; [
    colima
    docker
    docker-compose
  ];

  # Run Colima from the primary user's launchd domain so Lima never runs as root.
  launchd.user.agents."colima.default" = {
    command = "${pkgs.colima}/bin/colima start --foreground";
    serviceConfig = {
      Label = "com.colima.default";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/colima.log";
      StandardErrorPath = "/tmp/colima.error.log";
      EnvironmentVariables = {
        HOME = "/Users/${config.system.primaryUser}";
        PATH = "/Users/${config.system.primaryUser}/.nix-profile/bin:${pkgs.colima}/bin:${pkgs.docker}/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };
}
