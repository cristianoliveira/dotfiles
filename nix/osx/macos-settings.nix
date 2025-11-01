{
  system = {
    keyboard.enableKeyMapping = true;
    keyboard.remapCapsLockToControl = true;

    # Global defaults for macOS
    # NOTE: After changing these settings, you may need to run:
    # `killall SystemUIServer`
    defaults = {
      # Keyboard settings
      # Enable full keyboard access for all controls
      # (e.g. enable Tab in modal dialogs)
      # define delays, keyrepeat and press and hold
      NSGlobalDomain = {
        AppleKeyboardUIMode = 3;
        _HIHideMenuBar = true;

        InitialKeyRepeat = 10;
        KeyRepeat = 1;
        ApplePressAndHoldEnabled = false;
        # set fn properly
        "com.apple.keyboard.fnState" = true;

        # Touchpad settings
        # Speed of the cursor
        "com.apple.trackpad.scaling" = 3.0; # 1 ~ 3

        # Finder default
        AppleShowAllFiles = true;
      };

      # NOTE: This is not working, but it should
      # ERROR: defaults[41922:398520] Could not write domain com.apple.universalaccess; exiting
      # universalaccess.reduceMotion = true;

      # Dock configs
      dock = {
        autohide = true; # Automatically hide and show the Dock
        mru-spaces = false; # Disable automatic rearrangement of Spaces based on most recent use
        static-only = true; # Only show open applications in the Dock
        tilesize = 12; # Set the icon size of Dock items (small but still usable)
      };

      # Finder and file managment
      finder = {
        AppleShowAllFiles = true;
        _FXShowPosixPathInTitle = true;
      };

      # Group windows in Mission Control
      CustomUserPreferences = {
        "com.apple.dock" = {
          "expose-group-apps" = 1;
          "expose-group-apps-enabled" = 1;
        };
      };
    };
  };

  environment.variables = {
    # Xcode path for command line tools
    # Make sure to install Xcode from the App Store
    DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer";
  };
}
