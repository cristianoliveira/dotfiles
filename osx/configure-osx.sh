#!/usr/bin/env bash
# based on https://github.com/mathiasbynens/dotfiles/blob/master/.osx

if [ $# -ne 1 ]
then
  echo 'Usage: ./configure-osx "computer_name"'
  exit 1
fi

computer_name="$1"

# Set machine name
echo; echo ">> Setting computer name to '$computer_name'"
sudo scutil --set ComputerName "$computer_name"
sudo scutil --set HostName "$computer_name"
sudo scutil --set LocalHostName "$computer_name"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$computer_name"

# Trackpad/Mouse settings
# tap to click
# it is not really working
#defaults -currentHost write -g com.apple.mouse.tapBehavior -bool true
#defaults write -g com.apple.mouse.tapBehavior -bool true
#defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
#defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true

# swipe
echo; echo ">> Configuring trackpad gestures"
defaults -currentHost write -g com.apple.trackpad.fiveFingerPinchSwipeGesture -int 2

defaults -currentHost write -g com.apple.trackpad.fourFingerHorizSwipeGesture -int 2
defaults -currentHost write -g com.apple.trackpad.fourFingerPinchSwipeGesture -int 2
defaults -currentHost write -g com.apple.trackpad.fourFingerVertSwipeGesture -int 2

defaults -currentHost write -g com.apple.trackpad.threeFingerDragGesture -int 0
defaults -currentHost write -g com.apple.trackpad.threeFingerHorizSwipeGesture -int 2
defaults -currentHost write -g com.apple.trackpad.threeFingerTapGesture -int 2
defaults -currentHost write -g com.apple.trackpad.threeFingerVertSwipeGesture -int 2

defaults -currentHost write -g com.apple.trackpad.twoFingerDoubleTapGesture -int 1
defaults -currentHost write -g com.apple.trackpad.twoFingerFromRightEdgeSwipeGesture -int 3

defaults -currentHost write -g com.apple.trackpad.enableSecondaryClick -bool true
defaults -currentHost write -g com.apple.trackpad.pinchGesture -bool true
defaults -currentHost write -g com.apple.trackpad.rotateGesture -bool true
defaults -currentHost write -g com.apple.trackpad.scrollBehavior -int 2

# Keyboard settings
# Enable full keyboard access for all controls
# (e.g. enable Tab in modal dialogs)
echo; echo ">> Configuring keyboard"
defaults write -g AppleKeyboardUIMode -int 3

# set fn properly
defaults write -g com.apple.keyboard.fnState -bool true

# define delays, keyrepeat and press and hold
defaults write -g InitialKeyRepeat -int 10
defaults write -g KeyRepeat -float 1.2
defaults write -g ApplePressAndHoldEnabled -bool false

# set control to zoom
defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144

# set background lighting properly
defaults write com.apple.BezelServices kDim -bool true
defaults write com.apple.BezelServices kDimTime -int 300

# use capslock as control
keyboard_ids=$(ioreg -n IOHIDKeyboard -r | grep -E 'VendorID\>|ProductID\>' | awk '{ print $4 }' | paste -s -d'-\n' -)
echo $keyboard_ids | xargs -I{} sh -c 'defaults -currentHost read -g "com.apple.keyboard.modifiermapping.{}-0" | grep "Dst = 2" > /dev/null'
if [[ $? -ne 0 ]]; then
  echo $keyboard_ids | xargs -I{} defaults -currentHost write -g "com.apple.keyboard.modifiermapping.{}-0" -array "<dict><key>HIDKeyboardModifierMappingDst</key><integer>2</integer><key>HIDKeyboardModifierMappingSrc</key><integer>0</integer></dict>"
fi

# Use proper units
echo; echo ">> Configuring measurement units"
defaults write -g AppleMeasurementUnits -string "Centimeters"
defaults write -g AppleMetricUnits -bool true

# Mission Control
echo; echo ">> Configuring Mission Control"
defaults write com.apple.dock expose-animation-duration -float 0.12
# Save screenshot as a png
defaults write com.apple.screencapture type -string 'png'

# screen corners
# Top Left - Application Windows
defaults write com.apple.dock wvous-tl-corner -int 3
defaults write com.apple.dock wvous-tl-modifier -int 0
# Bottom Left - Dashboard
defaults write com.apple.dock wvous-bl-corner -int 7
defaults write com.apple.dock wvous-bl-modifier -int 0
# Top Right - Mission Control
defaults write com.apple.dock wvous-tr-corner -int 2
defaults write com.apple.dock wvous-tr-modifier -int 0
# Bottom Righ - Desktop
defaults write com.apple.dock wvous-br-corner -int 4
defaults write com.apple.dock wvous-br-modifier -int 0

## Spaces / Dock
# Enable Dashboard
defaults write com.apple.dashboard enabled-state -int 2
# Don’t automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false
# Disable Magnification
defaults write com.apple.dock magnification -bool false
# Enable app expose
defaults write com.apple.dock showAppExposeGestureEnabled -bool true

# Enable highlight hover effect for the grid view of a stack
defaults write com.apple.dock mouse-over-hilte-stack -bool true
# Set the icon size of Dock items
defaults write com.apple.dock tilesize -int 43
# Enable spring loading for all Dock items
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# require password after screen lock
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Finder
# Style - Dark Mode
echo; echo ">> Configuring Finder Control"
defaults write -g AppleInterfaceStyle -string 'Dark'

# increase window resize speed for Cocoa applications
defaults write -g NSWindowResizeTime -float 0.001
# decrease delay on spring loaded folder to the second level
defaults write -g com.apple.springing.enabled -bool true
defaults write -g com.apple.springing.delay -float 0.5

# Show connected servers on desktop
# External Hard Drive
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
# Hard Drive
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
# Mounted Servers
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
# Removable Media
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Remove warning when changing extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false
defaults write com.apple.finder EmptyTrashSecurely -bool true
# Finder windows
defaults write com.apple.finder ShowStatusBar -bool false
defaults write com.apple.finder ShowPathbar -bool true
# Enable AirDrop over Ethernet and on unsupported Macs running Lion
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

## Apps

echo; echo ">> Configuring Apps"
## Safari
echo; echo ">> Configuring Safari"
#Prevent from opening ‘safe’ files automatically after downloading
defaults write -app Safari AutoOpenSafeDownloads -bool false
#Enable debug mode
defaults write -app Safari IncludeInternalDebugMenu -bool true
#Make Safari’s search banners default to Contains instead of Starts With
defaults write -app Safari FindOnPageMatchesWordStartsOnly -bool false
#Press Tab to highlight each item on a web page
defaults write -app Safari WebKitTabToLinksPreferenceKey -bool true
defaults write -app Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2TabsToLinks -bool true
#Show the full URL in the address bar (note: this still hides the scheme)
defaults write -app Safari ShowFullURLInSmartSearchField -bool true
#Enable the Develop menu and the Web Inspector in Safari
defaults write -app Safari IncludeDevelopMenu -bool true
defaults write -app Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write -app Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
#Add a context menu item for showing the Web Inspector in web views
defaults write -g WebKitDeveloperExtras -bool true

# iTerm
echo; echo ">> Configuring iTerm"
# Don’t display the annoying prompt when quitting iTerm
defaults write -app iterm PromptOnQuit -bool false
defaults write -app iterm SmartPlacement -bool true
defaults write -app iterm DisableFullscreenTransparency -bool true
defaults write -app iterm AdjustWindowForFontSizeChange -bool false
defaults write -app iterm QuitWhenAllWindowsClosed -bool true


# Transmission
echo; echo ">> Configuring Transmission"
# Don’t prompt for confirmation before downloading
defaults write -app transmission DownloadAsk -bool false
# Trash original torrent files
defaults write -app transmission DeleteOriginalTorrent -bool true
# Hide the donate message
defaults write -app transmission WarningDonate -bool false
# Hide the legal disclaimer
defaults write -app transmission WarningLegal -bool false

echo; echo ">> Killing affected apps"
for app in "Dock" "Finder" "SystemUIServer" "Safari" "Transmission" "iTerm"; do
  killall "${app}" > /dev/null 2>&1
done
echo "Done. Note that some of these changes require a logout/restart to take effect."
