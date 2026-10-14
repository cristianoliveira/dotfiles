{ pkgs, ... }: {
  systemd.user.services.on-demand-services = {
    description = "On-demand user services managed by process-compose";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.process-compose}/bin/process-compose --config /etc/process-compose/services.yaml --no-server --tui=false up";
      Environment = [
        "PATH=%h/.nix-profile/bin:/run/current-system/sw/bin:/usr/bin:/bin"
      ];
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
