#!/bin/bash
# Zips the source code so someone else can build and install ClipStack with ./install.sh.
#   ./scripts/package_source.sh  ->  dist/ClipStack-source-<version>.zip
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(sed -n 's/^VERSION="\(.*\)"/\1/p' build.sh)
STAGE="build/source/ClipStack"
ZIP="dist/ClipStack-source-$VERSION.zip"

rm -rf build/source
mkdir -p "$STAGE" dist
for item in Package.swift Sources Resources scripts .github \
            build.sh install.sh uninstall.sh README.md AGENTS.md "Read Me - ClipStack.txt" .gitignore; do
  cp -R "$item" "$STAGE/"
done
find "$STAGE" -name .DS_Store -delete

rm -f "$ZIP"
# Plain zip (no macOS resource forks) so it unpacks cleanly anywhere and keeps the scripts executable.
(cd build/source && zip -qr -X "../../$ZIP" ClipStack)
echo "$ZIP"
