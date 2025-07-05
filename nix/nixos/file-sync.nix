{ pkgs, ... }: {
  # This module provides file synchronization tools like rclone.
  environment.systemPackages = with pkgs; [
    rclone
  ];

  systemd.timers.rcloneBisync = {
    description = "Rclone bisync every hour";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

  systemd.services.rcloneBisync = {
    description = "Rclone bisync service";
    serviceConfig = let 
        # FIXME: use $HOME instead of hardcoding the path
        # userDir = builtins.getEnv "HOME";
        userDir = "/home/cristianoliveira"; # Replace with your actual username
        cmd = builtins.concatStringsSep " " [
          "${pkgs.rclone}/bin/rclone"
          "--config=${userDir}/.config/rclone/rclone.conf"
          "bisync"
          "${userDir}/notes"
          "gdrive:/notes"
          "--resync"
        ];
      in {
      ExecStart = "${cmd}";
    };
  };
}
