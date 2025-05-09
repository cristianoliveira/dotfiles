# Webapps for macos

To turn any website into an desktop app, you can use the following steps

 - Open the website in Chrome/Brave
 - Click on the three dots in the top right corner
 - Go to "More tools" or "Save and Share"
 - Click on "Create shortcut" or "Install app"
 - It will create a Desktor entry in ~/Applications/Chrome Apps.localized.app/YourWebsite.app
 - Move that to this folder
 - Use make stow to link it later

on Chrome, navigate to the website.

```bash
mv ~/Applications/Chrome\ Apps.localized.app/YourWebsite.app ~/.dotfiles/nix/osx/Applications/
make stow
```
