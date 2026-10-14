{ config, pkgs ? import <nixpkgs> {}, ... }: {
  environment.systemPackages = with pkgs; [
    colima
    docker
    docker-compose
  ];

  # Start Colima at login with the user environment Lima expects.
  launchd.agents."colima.default" = {
    command = "${pkgs.colima}/bin/colima start --foreground";
    serviceConfig = {
      Label = "com.colima.default";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/log/colima.log";
      StandardErrorPath = "/var/log/colima.error.log";
      EnvironmentVariables = {
        HOME = "/Users/${config.system.primaryUser}";
        PATH = "${pkgs.colima}/bin:${pkgs.docker}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };
}
