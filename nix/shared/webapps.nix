{ pkgs }:

{
  googlekeep = pkgs.writeShellApplication {
    name = "google-keep";
    text = ''
#!/bin/sh
      set -e
      brave -app=https://keep.google.com
      '';
  };

  chatgpt = pkgs.writeShellApplication {
    name = "chatgpt";
    text = ''
#!/bin/sh
      set -e
      brave -app=https://chat.openai.com
      '';
  };

  youtube = pkgs.writeShellApplication {
    name = "youtube";
    text = ''
#!/bin/sh
      set -e
      brave -app=https://www.youtube.com
      '';
  };
}
