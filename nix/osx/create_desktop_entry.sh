#!/bin/bash

set -e

read -p "Enter the name of your app (e.g., MyApp): " APP_NAME
read -p "Enter the command to run (e.g., htop, /path/to/script.sh): " CMD

APP_DIR="$HOME/.dotfiles/nix/osx/Applications/${APP_NAME}.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

echo "Creating app bundle at $APP_DIR..."
mkdir -p "$MACOS_DIR"

# Create launcher script
cat > "$MACOS_DIR/$APP_NAME" <<EOF
#!/bin/bash
exec ${CMD} "\$@"
EOF

chmod +x "$MACOS_DIR/$APP_NAME"

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.user.${APP_NAME}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
</dict>
</plist>
EOF

# Re-index for Spotlight
echo "Re-indexing app for Spotlight..."
mdimport "$APP_DIR"

echo "✅ Done! You can now find \"$APP_NAME\" in Spotlight."
