{
  system.defaults.CustomUserPreferences = let
    editCommand = {
      # Doesn 't work as expected, but it is the only way to set these
      # "Cut" = "^x";
      # "Copy" = "^c";
      # "Paste" = "^v";
      # "Paste and Match Style" = "^\$v";
    };

    chromiumMappings = {
        # How to find these? Check the menu title in the app

        # Tabs
        "New Tab" = "^t";
        "New Window" = "^n";
        "New Incognito Window" = "^\$n";
        "Close Tab" = "^w";
        "Reopen Closed Tab" = "^\$t";
        "Search Tabs..." = "^p";
        "Move Tab to New Window" = "W";
         
        # Navigating (vim like)
        "Back" = "^o";
        "Forward" = "^i";
        "Reload This Page" = "^r";

        # Focus
        "Open Location..." = "^l";
      };
  in {
    "com.google.Chrome" = {
      "NSUserKeyEquivalents" = chromiumMappings // editCommand;
    };
    "com.brave.Browser" = {
      "NSUserKeyEquivalents" = chromiumMappings // editCommand;
    };

    "md.obsidian" = {
      "NSUserKeyEquivalents" = {
        # Obsidian specific shortcuts
        "New Note" = "^n";

        # ctrl+p file search
        "Open Quickly..." = "^p";
        # "Search Files" = "^f";
        # "Toggle Sidebars" = "^b";
        # "Toggle Preview Mode" = "^m";
        # "Toggle Edit Mode" = "^e";
        # "Open Settings" = "^,";
        # "Open Graph View" = "^g";

        # Vim like navigation
        "Navigate Back" = "^o";
        "Navigate Forward" = "^i";
      } // editCommand;
    };
  };
}
