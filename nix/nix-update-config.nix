{ pkgs ,... }: 
  pkgs.stdenv.mkDerivation {
    name = "nix-update-config";
    src = ../.;
# See https://stackoverflow.com/questions/67963396/how-to-read-file-and-apply-substitutions-to-its-content
    buildPhase = ''
      mkdir -p $out/config

      mkdir -p $out/config/nix

      cp "$src/nix/nix.conf" "$out/config/nix/nix.conf"

      cp -rf "$src/nix/osx/yabai/yabairc" "$out/config/.yabairc"
      cp -rf "$src/nix/osx/yabai/skhdrc" "$out/config/.skhdrc"

      cp -rf "$src/nix/osx/karabiner" "$out/config/karabiner"

      cp -rf "$src/nix/osx/finicky/finicky.js" "$out/config/.finicky.js"
      cp -rf "$src/nix/shared/alacritty" "$out/config/alacritty"

      cp -rf "$src/nvim" "$out/config/nvim"
      cp -rf "$src/zsh" "$out/config/zsh"
      cp -rf "$src/tmux" "$out/config/tmux"

      echo "#!/bin/sh" > $out/setup.sh
      echo "" >> $out/setup.sh
      echo "ln -s $out/config ~/config" >> $out/setup.sh
      echo "ln -s $out/config/zsh/zshrc ~/.zshrc" >> $out/setup.sh
      echo "ln -s $out/config/tmux/tmux.conf ~/.zshrc" >> $out/setup.sh
      chmod +x $out/setup.sh
      '';

    installPhase = ''
      mkdir -p $out/bin
      mv $out/setup.sh $out/bin/nix-update-config
      '';
  }
