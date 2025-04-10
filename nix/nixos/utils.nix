# Utils module
# Here contains a bunch of packages that are yet not categorized
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # network cli helpers
    lsof # list open files and ports normal usage `lsof -i :8080`
  ];
}
