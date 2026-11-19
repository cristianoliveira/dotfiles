{ pkgs ? import <nixpkgs> {}, ... }: {
  environment.systemPackages = with pkgs; [
    colima
    docker
    docker-compose
  ];

}
