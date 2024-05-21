{ config, pkgs, ... }: 
{
  # Maps Capslock to ESC when pressed and CTRL when holding
  services.interception-tools = {
    enable = true;
    plugins = with pkgs; [
      interception-tools-plugins.dual-function-keys
    ];
    # caps2esc maps caps to control only when pressing with another key
    # that is an issue for shortcuts in programs like chorme where you need to press
    # ctrl + click to open a link in a new tab
    udevmonConfig = with pkgs;''
      - JOB: "${interception-tools}/bin/intercept -g $DEVNODE | \
        ${interception-tools-plugins.dual-function-keys}/bin/dual-function-keys \
          -c /etc/mappings/dual-keys-mappings.yaml | \
        ${interception-tools}/bin/uinput -d $DEVNODE"
        DEVICE:
          EVENTS:
            EV_KEY: [KEY_ESC, KEY_CAPSLOCK]
    '';
  };

}
