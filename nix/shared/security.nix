# Security related packages
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    gnupg
    pinentry # Required to generate gpg keys
  ];
}
