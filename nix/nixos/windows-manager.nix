{ _config, pkgs, _lib, ... }:
{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # so that gtk works properly
    extraPackages = with pkgs; [
      swaylock
      i3status
      swayidle

      autotiling

      # Keybindings daemon
      # NOTE try `sxhkd` to decouple keybindings from the window manager

      # Notifications
      mako

      # Utilities
      wf-recorder
      grim # screenshot functionality
      slurp # screenshot functionality
      wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout

      # GUIs for common settings
      pavucontrol # audio manager
      playerctl # media player control

      # Launcher
      dmenu # Dmenu is the default in the config but i recommend wofi since its wayland native
      ulauncher

      # Displays UI manager
      wdisplays

      # Persistent object states
      copkgs.sway-setter
    ];

    xwayland.enable = true;
  };

  ## This here isn't really necessary for the fix but let's ake sure
  # to explicitly enable and start the xdg-desktop-portal-* as services on login
  xdg.portal = {
    enable = true;

    # Expected by xdg-desktop-portal
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  ## Other related GUIS for settings
  # Bluetooth related 
  hardware.bluetooth = {
    enable = true;
  };

  # Enable sound with pipewire.
  # See: https://nixos.wiki/wiki/PipeWire
  # sound.enable = true;
  # hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };

    # Enable CUPS to print documents.
    printing.enable = true;
  };

  # Sway related services
  systemd = {
    services = {
      swayaudioinhibit = {
        enable = true;
        # Prevents the screen from going to sleep when audio is playing
        # For when having zoom calls or watching videos
        description = "Sway audio inhibit";

        after = [ "multi-user.target" ];
        wantedBy = [ "multi-user.target" ];
        partOf = [ "multi-user.target" ];

        environment = {
          WAYLAND_DISPLAY = "wayland-1";
          XDG_RUNTIME_DIR = "/run/user/1000";
        };

        serviceConfig = {
          User = "cristianoliveira";
          Group = "users";
          Type = "simple";
          ExecStart = "${pkgs.sway-audio-idle-inhibit}/bin/sway-audio-idle-inhibit";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      notifications = {
        wantedBy = [ "multi-user.target" ];

        script = ''
          set -eu

          while true; do

            BATTERY="/sys/class/power_supply/BAT0"

            capacity="$(cat "$BATTERY/capacity")"
            status="$(cat "$BATTERY/status")"
            if [ "$status" = "Discharging" ] && [ "$capacity" -le 15 ]; then
              ${pkgs.libnotify}/bin/notify-send \
                "⚠ Battery low" \
                "Battery is at $capacity%"
            fi

            if [ "$status" = "Discharging" ] && [ "$capacity" -le 4 ]; then
              ${pkgs.libnotify}/bin/notify-send \
                --urgency=critical \
                "⚠ Battery critical" \
                "Critically low batery, save your work!"

                sleep 180
                systemctl suspend
            fi

            sleep 180
          done
        '';

        environment = {
          WAYLAND_DISPLAY = "wayland-1";
          XDG_RUNTIME_DIR = "/run/user/1000";
        };

        serviceConfig = {
          User = "cristianoliveira";
          Group = "users";
          Type = "simple";
          Restart = "always";
          RestartSec = "5s";
        };
      };
    };
  };
}
