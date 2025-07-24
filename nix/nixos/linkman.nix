_: {
  # Manage dotfiles using linkman 
  # See: https://github.com/cristianoliveira/nix-linkman
  services.linkman = rec {
    enable = true;

    targets = rec {
      "home" = "~/";
      "config" = "~/.config";
      "local" = "~/.local";

      # Ensure these mutable directories exist so
      # that linkman can create links in them
      "ulauncher" = "${config}/ulauncher";
    };

    links = with targets; [
      # Standard
      { source = ../../nvim; target = "${config}/nvim"; }
      { source = ../../tmux; target = "${config}/tmux"; }
      { source = ../../zsh/zshrc; target = "${home}.zshrc"; }
      { source = ../../git/gitignore; target = "${home}.gitignore"; }
      { source = ../../git/gitconfig; target = "${home}.gitconfig"; }
      { source = ../../aichat; target = "${config}/aichat"; }

      # Shared
      { source = ../shared/alacritty; target = "${config}/alacritty"; }
      { source = ../shared/direnv; target = "${config}/direnv"; }

      # Linux specific
      { source = ./fonts; target = "${local}/share/fonts"; }
      { source = ./sway; target = "${config}/sway"; }
      { source = ./swaylock; target = "${config}/swaylock"; }
      { source = ./i3status; target = "${config}/i3status"; }
      { source = ./wofi; target = "${config}/wofi"; }

      # Ulauncher requires mutable links
      { 
        source = "~/.dotfiles/nix/nixos/ulauncher/settings.json";
        target = "${ulauncher}/settings.json";
      }
      { 
        source = "~/.dotfiles/nix/nixos/ulauncher/shortcuts.json";
        target = "${ulauncher}/shortcuts.json";
      }
      { 
        source = "~/.dotfiles/nix/nixos/ulauncher/extensions.json";
        target = "${ulauncher}/extensions.json";
      }
    ];

    user = "cristianoliveira";
    group = "users";
  };
}
