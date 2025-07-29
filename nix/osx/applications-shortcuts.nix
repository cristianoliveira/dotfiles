{
  system.defaults.CustomUserPreferences = let
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

        # Page Actions 
        "Cut" = "^x";
        "Copy" = "^c";
        "Paste" = "^v";
        "Paste and Match Style" = "^\$v";
        "Select All" = "^a";
        "Redo" = "^y";
        "Undo" = "^z";
        "Find..." = "^f";
      };
  in {
    "com.google.Chrome" = {
      "NSUserKeyEquivalents" = chromiumMappings;
    };
    "com.brave.Browser" = {
      "NSUserKeyEquivalents" = chromiumMappings;
    };
  };
}
