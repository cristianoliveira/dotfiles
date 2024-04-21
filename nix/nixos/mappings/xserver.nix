{ config, ... }: 
{
  # Maps caps to ctrl
  services.xserver = {
    # Enable the X11 windowing system.
    enable = true;
    # Enable the GNOME Desktop Environment.
    # displayManager.gdm.enable = true;

    # Configure keymap in X11
    layout = "us";
    xkbVariant = "";
    xkbOptions = "altwin:swap_lalt_lwin";

    # Keyboard repeat rate
    autoRepeatDelay = 100;
    autoRepeatInterval = 5;

    # Enable touchpad support (enabled default in most desktopManager).
    libinput.enable = true;
  };
}
