{ pkgs, ... }:
let
  primaryUser = "cristianoliveira";
  pruneScript = "/Users/${primaryUser}/.local/bin/prune-devenv";
in {
  launchd.agents.prune-devenv = {
    command = "${pkgs.bash}/bin/bash ${pruneScript} --apply --days 30";
    serviceConfig = {
      Label = "com.cristianoliveira.prune-devenv";
      StartCalendarInterval = {
        Weekday = 1;
        Hour = 3;
        Minute = 0;
      };
      StandardOutPath = "/tmp/prune-devenv.log";
      StandardErrorPath = "/tmp/prune-devenv-error.log";
      EnvironmentVariables = {
        PATH = "${pkgs.fd}/bin:${pkgs.nix}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };
}
