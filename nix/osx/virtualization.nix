{ pkgs ? import <nixpkgs> {}, ... }: {
  # Enable virtualization with colima and launchd
  launchd.agents."colima.default" = {
    command = "${pkgs.colima}/bin/colima start --foreground";
    serviceConfig = {
      Label = "com.colima.default";
      RunAtLoad = true;
      KeepAlive = true;

# not sure where to put these paths and not reference a hard-coded `$HOME`; `/var/log`?
      StandardOutPath = "/var/log/colima.log";
      StandardErrorPath = "/var/log/colima.error.log";

# not using launchd.agents.<name>.path because colima needs the system ones as well
      EnvironmentVariables = {
        PATH = "${pkgs.colima}/bin:${pkgs.docker}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };
}
