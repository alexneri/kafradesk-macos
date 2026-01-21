#!/bin/bash
set -euo pipefail

APP_PATH="build/export/Kafra Desktop Assistant.app"
DMG_PATH="build/Kafra_Desktop_Assistant_v1.0.0.dmg"
VOLUME_NAME="Kafra Desktop Assistant"

if [ ! -d "$APP_PATH" ]; then
  echo "App not found at $APP_PATH"
  exit 1
fi

echo "Creating DMG..."
hdiutil create -volname "$VOLUME_NAME" \
  -srcfolder "$APP_PATH" \
  -ov -format UDZO \
  "$DMG_PATH"

echo "DMG created: $DMG_PATH"
