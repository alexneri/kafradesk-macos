#!/bin/bash
set -euo pipefail

PROJECT_NAME="Kafra Desktop Assistant"
SCHEME="Kafra Desktop Assistant"
ARCHIVE_PATH="build/Kafra_Desktop_Assistant.xcarchive"
EXPORT_PATH="build/export"
APP_NAME="Kafra Desktop Assistant.app"

mkdir -p build

xcodebuild archive \
  -project "Kafra Desktop Assistant/Kafra Desktop Assistant.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH"

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "scripts/ExportOptions.plist"

echo "Build complete: $EXPORT_PATH/$APP_NAME"
