#!/bin/bash
set -euo pipefail

APP_PATH="build/export/Kafra Desktop Assistant.app"
ZIP_PATH="build/Kafra_Desktop_Assistant.zip"

# Store credentials in keychain first:
# xcrun notarytool store-credentials "AC_PASSWORD" \
#   --apple-id "you@example.com" \
#   --team-id "YOUR_TEAM_ID" \
#   --password "app-specific-password"

if [ ! -d "$APP_PATH" ]; then
  echo "App not found at $APP_PATH"
  exit 1
fi

echo "Creating notarization ZIP..."
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Submitting for notarization..."
xcrun notarytool submit "$ZIP_PATH" \
  --keychain-profile "AC_PASSWORD" \
  --wait

echo "Stapling ticket..."
xcrun stapler staple "$APP_PATH"

echo "Notarization complete."
