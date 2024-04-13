{ config, pkgs, lib, ... }:
{
  environment.systemPackages = [
    # https://nixos.wiki/wiki/OBS_Studio
    (pkgs.wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
      ];
    })
  ];
}
