{ config, pkgs, ... }: {
  launchd.user.agents.on-demand-services = {
    command = ''
      ${pkgs.process-compose}/bin/process-compose \
        --config /etc/process-compose/services.yaml \
        --no-server \
        --tui=false \
        up
    '';
    serviceConfig = {
      Label = "com.cristianoliveira.on-demand-services";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/Users/${config.system.primaryUser}/Library/Logs/on-demand-services.log";
      StandardErrorPath = "/Users/${config.system.primaryUser}/Library/Logs/on-demand-services.error.log";
      EnvironmentVariables = {
        HOME = "/Users/${config.system.primaryUser}";
        PATH = "/Users/${config.system.primaryUser}/.nix-profile/bin:${pkgs.process-compose}/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };
}
