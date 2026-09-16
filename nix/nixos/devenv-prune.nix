{ pkgs, ... }:
let
  primaryUser = "cristianoliveira";
in {
  systemd.services.prune-devenv = {
    description = "Prune stale project devenv environments";
    serviceConfig = {
      Type = "oneshot";
      User = primaryUser;
      ExecStart = "${pkgs.bash}/bin/bash /home/${primaryUser}/.local/bin/prune-devenv --apply --days 30";
      Environment = "PATH=${pkgs.fd}/bin:${pkgs.nix}/bin:/run/current-system/sw/bin:/usr/bin:/bin";
    };
  };

  systemd.timers.prune-devenv = {
    description = "Weekly stale devenv cleanup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Mon *-*-* 03:00:00";
      Persistent = true;
    };
  };
}
