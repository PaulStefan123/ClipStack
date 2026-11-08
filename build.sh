#!/bin/bash
# Builds ClipStack.app (universal: Apple Silicon + Intel) and a shareable zip.
#
#   ./build.sh            -> build/ClipStack.app and dist/ClipStack-<version>.zip
#   ./build.sh --install  -> also copies the app to /Applications and launches it
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="ClipStack"
BUNDLE_ID="com.clipstack.app"
VERSION="1.0.0"
BUILD_DIR="build"
APP="$BUILD_DIR/$APP_NAME.app"

echo "==> Compiling (arm64 + x86_64)"
for ARCH in arm64 x86_64; do
  swift build -c release --triple "$ARCH-apple-macosx13.0" --scratch-path ".build/$ARCH"
done

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create \
  ".build/arm64/release/$APP_NAME" \
  ".build/x86_64/release/$APP_NAME" \
  -output "$APP/Contents/MacOS/$APP_NAME"

if [ ! -f Resources/AppIcon.icns ]; then
  echo "==> Rendering icon"
  rm -rf "$BUILD_DIR/AppIcon.iconset"
  swift scripts/make_icon.swift "$BUILD_DIR/AppIcon.iconset"
  iconutil -c icns "$BUILD_DIR/AppIcon.iconset" -o Resources/AppIcon.icns
fi
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleExecutable</key><string>$APP_NAME</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSHumanReadableCopyright</key><string>Free to use and share.</string>
</dict>
</plist>
PLIST

echo "==> Signing (ad-hoc)"
codesign --force --deep --sign - "$APP"

echo "==> Packaging"
mkdir -p dist
ZIP="dist/$APP_NAME-$VERSION.zip"
rm -f "$ZIP"
# Zip a "ClipStack" folder holding the app and the install guide for recipients.
STAGE="$BUILD_DIR/package/$APP_NAME"
rm -rf "$BUILD_DIR/package"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
cp "Read Me - ClipStack.txt" "$STAGE/"
ditto -c -k --keepParent "$STAGE" "$ZIP"
echo "    $ZIP"

if [ "${1:-}" = "--install" ]; then
  echo "==> Installing to /Applications"
  pkill -x "$APP_NAME" 2>/dev/null || true
  sleep 0.5
  rm -rf "/Applications/$APP_NAME.app"
  cp -R "$APP" /Applications/
  open "/Applications/$APP_NAME.app"
fi

echo "Done."
