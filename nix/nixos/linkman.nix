_: {
  # Manage dotfiles using linkman 
  # See: https://github.com/cristianoliveira/nix-linkman
  services.linkman = rec {
    enable = true;

    targets = rec {
      # Standard directories
      "home" = "~/";
      "config" = "~/.config";
      "local" = "~/.local";

      # Aplication specific directories
      "ctags" = "~/.ctags.d";
      # Ensure these mutable directories exist so
      # that linkman can create links in them
      "ulauncher" = "${config}/ulauncher";
      "applications" = "${local}/share/applications";
    };

    links = with targets; [
      # Standard
      { source = ../../nvim; target = config; }
      { source = ../../tmux; target = config; }
      { source = ../../zsh/zshrc; target = "${home}.zshrc"; }
      { source = ../../git/gitignore; target = "${home}.gitignore"; }
      { source = ../../git/gitconfig; target = "${home}.gitconfig"; }
      { source = ../../ai/aichat; target = config; }
      { source = ../../ctags; target = "${ctags}/default.ctags"; }

      # Shared
      { source = ../shared/alacritty; target = config; }
      { source = ../shared/direnv; target = config; }

      # Linux specific
      { source = ./fonts; target = "${local}/share/fonts"; }
      { source = ./sway; target = config; }
      { source = ./swaylock; target = config; }
      { source = ./i3status; target = config; }
      { source = ./wofi; target = config; }

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

      # Application entries
      { 
        source = ./desktop-entries/chatgpt.desktop; 
        target = applications;
      }
      {
        source = ./desktop-entries/discord.desktop;
        target = applications;
      }
      {
        source = ./desktop-entries/gmail.desktop;
        target = applications;
      }
      {
        source = ./desktop-entries/google-keep.desktop;
        target = applications;
      }
      {
        source = ./desktop-entries/twitch.desktop;
        target = applications;
      }
      {
        source = ./desktop-entries/youtube.desktop;
        target = applications;
      }
      {
        source = ./desktop-entries/zapzap.desktop;
        target = applications;
      }
      
    ];

    user = "cristianoliveira";
    group = "users";
  };
}
