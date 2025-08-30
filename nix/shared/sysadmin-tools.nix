{ pkgs ? import <nixpkgs> {}, ... }: {
  environment.systemPackages = with pkgs; [
    nmap # Network exploration tool and security/port scanner
    htop # Interactive process viewer
  ];
}
