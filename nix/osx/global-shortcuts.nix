{
  system.defaults.CustomUserPreferences = {
    # This involves editing macOS private APIs or undocumented plist formats.
    # To find the correct keys, you can use `defaults read` on the terminal.
    # `defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys`
    "com.apple.symbolichotkeys" = {

      AppleSymbolicHotKeys = {
        # Disable all Mission Control shortcuts
        "184" =     {
          enabled = 0;
          value =         {
            type = "standard";
          };
        };

        # Disable all screen capture shortcuts
        "28" =     {
          enabled = 0;
          value =         {
            type = "standard";
          };
        };
        "29" =     {
          enabled = 0;
          value =         {
            type = "standard";
          };
        };
        "30" =     {
          enabled = 0;
          value =         {
            type = "standard";
          };
        };
        "31" =     {
          enabled = 0;
          value =         {
            type = "standard";
          };
        };
        "52" =     {
          enabled = 0;
          value =         {
            type = "standard";
          };
        };

        # Disable all Spotlight shortcuts
        "64" =     {
          enabled = 0;
          value =         {
            type = "standard";
          };
        };
        "65" =     {
          enabled = 0;
          value =         {
            type = "standard";
          };
        };
      };
    };
  };
}
