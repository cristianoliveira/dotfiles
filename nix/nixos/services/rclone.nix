{ pkgs, ... }: let
  user = "cristianoliveira";
  group = "users";
  notesDir = "/home/${user}/notes";
  sharedDir = "/home/${user}/shared";
  rcloneConfig = "/home/${user}/.config/rclone/rclone.conf";
in {
  systemd.tmpfiles.rules = [
    "d ${notesDir} 0755 ${user} ${group} -"
    "d ${sharedDir} 0755 ${user} ${group} -"
  ];

  systemd.services.rclone-notes-mount = {
    description = "Mount secondbrain notes with rclone";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "simple";
      User = user;
      Group = group;
      Environment = [ "NOTES=${notesDir}" ];
      ExecStart = ''${pkgs.rclone}/bin/rclone mount gdrive:notes/secondbrain ${notesDir} --config ${rcloneConfig} --vfs-cache-mode full --dir-cache-time 72h --poll-interval 30s'';
      ExecStop = ''-${pkgs.fuse3}/bin/fusermount3 -u ${notesDir}'';

      NoNewPrivileges = false;
      CapabilityBoundingSet = [ "CAP_SYS_ADMIN" ];
      AmbientCapabilities = [ "CAP_SYS_ADMIN" ];
      DeviceAllow = [ "/dev/fuse rw" ];
      PrivateDevices = false;
      ProtectHome = false;
      Restart = "always";
      RestartSec = "10s";
    };
  };

  systemd.services.rclone-shared-mount = {
    description = "Mount shared drive with rclone";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "simple";
      User = user;
      Group = group;
      Environment = [ "SHARED=${sharedDir}" ];
      ExecStart = ''${pkgs.rclone}/bin/rclone mount gdrive:shared_workspace ${sharedDir} --config ${rcloneConfig} --vfs-cache-mode full --dir-cache-time 72h --poll-interval 30s'';
      ExecStop = ''-${pkgs.fuse3}/bin/fusermount3 -u ${sharedDir}'';

      NoNewPrivileges = false;
      CapabilityBoundingSet = [ "CAP_SYS_ADMIN" ];
      AmbientCapabilities = [ "CAP_SYS_ADMIN" ];
      DeviceAllow = [ "/dev/fuse rw" ];
      PrivateDevices = false;
      ProtectHome = false;
      Restart = "always";
      RestartSec = "10s";
    };
  };
}
