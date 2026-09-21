{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    flashprint
    freecad
    orca-slicer
  ];
}
