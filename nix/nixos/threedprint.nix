{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    flashprint
    freecad
    unstable.orca-slicer
  ];
}
