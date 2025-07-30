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
      dock.autohide = true;

      # Finder and file managment
      finder = {
        AppleShowAllFiles = true;
        _FXShowPosixPathInTitle = true;
      };
    };
  };
}
