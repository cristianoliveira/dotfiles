{ pkgs, ... }: {
  # This module provides file synchronization tools like rclone.
  environment.systemPackages = with pkgs; [
    rclone
  ];

  systemd.services.rcloneBisync = {
    enabled = true;
    description = "Rclone bisync service";
    serviceConfig = let 
        userDir = "/home/cristianoliveira";

        # Mount grive:notes in $HOME/notes
        # rclone mount gdrive:notes $HOME/_notes  --cache-db-purge --fast-list --poll-interval 10 --allow-non-empty
        cmd = builtins.concatStringsSep " " [
          "${pkgs.rclone}/bin/rclone"
          "mount"
          "gdrive:notes"
          "${userDir}/notes"
          "--cache-db-purge"
          "--fast-list"
          "--poll-interval 10"
          "--allow-non-empty"
        ];
    in {
      User = "cristianoliveira";
      ExecStart = "${cmd}";
      Restart = "always";
      RestartSec = "10";
    };
  };
}
