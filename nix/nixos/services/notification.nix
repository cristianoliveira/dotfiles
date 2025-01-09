{ _, ... }:
# Notificatio service that watches for changes in the system
# and executes a command when a change is detected.
{ 
  systemd.services.notifier = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      # Link from $HOME/.dotfiles/nix/nixos/services
      ExecStart = "/var/services/notification.sh";
    };
  };
}
