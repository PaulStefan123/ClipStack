#!/bin/bash
# Removes ClipStack, its login item, its permission entry and its saved history.
set -uo pipefail

APP_NAME="ClipStack"
BUNDLE_ID="com.clipstack.app"

osascript -e "quit app \"$APP_NAME\"" >/dev/null 2>&1
pkill -x "$APP_NAME" 2>/dev/null
sleep 1

for dir in /Applications "$HOME/Applications"; do
  if [ -d "$dir/$APP_NAME.app" ]; then
    rm -rf "$dir/$APP_NAME.app" && echo "Removed $dir/$APP_NAME.app"
  fi
done

tccutil reset Accessibility "$BUNDLE_ID" >/dev/null 2>&1
rm -rf "$HOME/Library/Application Support/$APP_NAME"
defaults delete "$BUNDLE_ID" >/dev/null 2>&1

echo "ClipStack has been uninstalled."
echo "If it still appears in System Settings › General › Login Items, remove it there."
