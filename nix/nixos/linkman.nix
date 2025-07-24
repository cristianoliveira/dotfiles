_: let
  targets = rec {
    "home" = "~/";
    "home_config" = "~/.config";
    "home_local" = "~/.local";

    # Ensure these mutable directories exist so
    # that linkman can create links in them
    "ulauncher" = "${home_config}/ulauncher";
  };
 in {
  # Manage dotfiles using linkman 
  # See: https://github.com/cristianoliveira/nix-linkman
  services.linkman = rec {
    enable = true;

    inherit targets;

    links = [
      # Standard
      { source = ../../nvim; target = "~/.config/nvim"; }
      { source = ../../tmux; target = "~/.config/tmux"; }
      { source = ../../zsh/zshrc; target = "~/.zshrc"; }
      { source = ../../aichat; target = "~/.config/aichat"; }
      { source = ../../git/gitconfig; target = "~/.gitconfig"; }
      { source = ../../git/gitignore; target = "~/.gitignore"; }

      # Shared
      { source = ../shared/alacritty; target = "~/.config/alacritty"; }
      { source = ../shared/direnv; target = "~/.config/direnv"; }

      # Linux specific
      { source = ./fonts; target = "~/.local/share/fonts"; }
      { source = ./sway; target = "~/.config/sway"; }
      { source = ./swaylock/config; target = "~/.swaylock"; }
      { 
        source = ./ulauncher/settings.json;
        target = "${targets.ulauncher}/settings.json";
      }
      { 
        source = ./ulauncher/shortcuts.json;
        target = "${targets.ulauncher}/shortcuts.json";
      }
      { 
        source = ./ulauncher/extensions.json; 
        target = "${targets.ulauncher}/extensions.json";
      }
      { source = ./wofi; target = "~/.config/wofi"; }
    ];

    user = "cristianoliveira";
    group = "users";
  };
}

