{ pkgs }:
let
  image = ../../resources/wallpaper.jpg;
in  {
  theme = pkgs.stdenv.mkDerivation {
    name = "sddm-theme";

    src = pkgs.fetchFromGitHub {
      owner = "MarianArlt";
      repo = "sddm-sugar-dark";
      rev = "ceb2c455663429be03ba62d9f898c571650ef7fe";
      sha256 = "0153z1kylbhc9d12nxy9vpn0spxgrhgy36wy37pk6ysq7akaqlvy";
    };
    installPhase = ''
      mkdir -p $out

      ## Change the background color to a dark blue
      sed -i 's/#444/#010713/' ./Main.qml

      sed -i 's/ScaleImageCropped=true/ScaleImageCropped=false/' ./theme.conf

      ## Qt6 compatibility: SDDM on NixOS 26.05 runs the Qt6 greeter, but this
      ## theme was written for Qt5. QtGraphicalEffects was removed in Qt6 (now
      ## Qt5Compat.GraphicalEffects) and QtQuick.VirtualKeyboard moved to major 6.
      find . -name '*.qml' -exec sed -i \
        -e 's/import QtGraphicalEffects 1.0/import Qt5Compat.GraphicalEffects/' \
        -e 's/import QtQuick.VirtualKeyboard 2.3/import QtQuick.VirtualKeyboard/' \
        {} +

      cp -R ./* $out/
      rm -f $out/Background.jpg
      cp -r ${image} $out/Background.jpg
    '';
  };

  extraPackages = with pkgs; [
    qt6.qtdeclarative
    qt6.qt5compat
    qt6.qtvirtualkeyboard
  ]; 
}
