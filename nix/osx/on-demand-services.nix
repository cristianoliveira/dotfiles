{ pkgs, ... }:
let
  startOnDemandServices = pkgs.writeShellScript "start-on-demand-services" ''
    user=$(/usr/bin/id -un)
    home=$(/usr/bin/dscl . -read "/Users/$user" NFSHomeDirectory | /usr/bin/awk '{ print $2 }')

    if [ -z "$home" ]; then
      echo "Could not determine home directory for $user" >&2
      exit 1
    fi

    export HOME="$home"
    export PATH="$HOME/.nix-profile/bin:${pkgs.process-compose}/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin"

    exec ${pkgs.process-compose}/bin/process-compose \
      --config /etc/process-compose/services.yaml \
      --no-server \
      --tui=false \
      up
  '';
in {
  launchd.agents.on-demand-services = {
    command = "${startOnDemandServices}";
    serviceConfig = {
      Label = "com.cristianoliveira.on-demand-services";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/on-demand-services.log";
      StandardErrorPath = "/tmp/on-demand-services.error.log";
    };
  };
}
