# Security related packages
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    gnupg
  ];
}
