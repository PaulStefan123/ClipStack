#!/bin/bash
# ClipStack installer: builds the app from this folder and installs it.
#
#   ./install.sh
#
# Safe to run again to update. Building on your own Mac means macOS doesn't
# show the "unidentified developer" warning.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="ClipStack"
BUNDLE_ID="com.clipstack.app"

say()  { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
fail() { printf '\n\033[31mError:\033[0m %s\n' "$1" >&2; exit 1; }

# 1. Check the Mac
[ "$(uname -s)" = "Darwin" ] || fail "ClipStack only runs on macOS."
MACOS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
[ "$MACOS_MAJOR" -ge 13 ] || fail "ClipStack needs macOS 13 (Ventura) or newer. This Mac has $(sw_vers -productVersion)."

# 2. Check Apple's command line tools (they include the Swift compiler)
if ! xcode-select -p >/dev/null 2>&1 || ! command -v swift >/dev/null 2>&1; then
  say "Apple's command line tools are needed to build ClipStack"
  xcode-select --install 2>/dev/null || true
  fail "A macOS window should have opened. Click Install, wait for it to finish (5–15 min), then run ./install.sh again."
fi

# 3. Build
say "Building ClipStack (this takes about a minute the first time)"
./build.sh

# 4. Install. Use /Applications if we can write to it, otherwise ~/Applications.
if [ -w /Applications ]; then
  DEST="/Applications"
else
  DEST="$HOME/Applications"
  mkdir -p "$DEST"
fi
TARGET="$DEST/$APP_NAME.app"

UPDATING=false
[ -d "$TARGET" ] && UPDATING=true

say "Installing to $TARGET"
osascript -e "quit app \"$APP_NAME\"" >/dev/null 2>&1 || true
pkill -x "$APP_NAME" 2>/dev/null || true
sleep 1
rm -rf "$TARGET"
cp -R "build/$APP_NAME.app" "$DEST/"
xattr -dr com.apple.quarantine "$TARGET" 2>/dev/null || true

# A rebuilt app counts as a new app to macOS, so the old Accessibility
# permission no longer applies. Clear it so macOS asks again cleanly.
if $UPDATING; then
  tccutil reset Accessibility "$BUNDLE_ID" >/dev/null 2>&1 || true
fi

# 5. Launch. ClipStack turns on "open at login" itself on first launch.
say "Starting ClipStack"
open "$TARGET"

cat <<EOF

✅ ClipStack is installed and running. Look for the clipboard icon in the menu bar.

ONE MANUAL STEP LEFT (macOS doesn't allow scripts to do this):
  When macOS asks "ClipStack would like to control this computer using
  accessibility features", click "Open System Settings" and turn on ClipStack.
  Then quit ClipStack from its menu bar icon and open it again.

  If ClipStack is already listed and turned on but pasting doesn't work,
  select it, click "–", then click "+" and add $TARGET again.

How to use it:
  ⌘C copy as usual  ·  ⌥⌘V open the list  ·  ↑↓ choose  ·  Return paste
  Settings: menu bar icon › Settings…

EOF
