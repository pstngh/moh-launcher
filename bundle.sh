#!/bin/sh
# Builds launcher.app for Apple silicon Macs with macOS 15 or later into a
# game folder, with install.command beside it.
#
# Usage: bundle.sh [game folder, default: current folder]
set -eu

src=$(cd "$(dirname "$0")" && pwd)
out=${1:-.}
app="$out/launcher.app"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
xcrun --sdk macosx swiftc -O -swift-version 5 -parse-as-library -target arm64-apple-macos15 \
    -o "$app/Contents/MacOS/launcher" "$src/Launcher.swift"
cp "$src/Info.plist" "$app/Contents/"
cp "$src/AppIcon.icns" "$app/Contents/Resources/"
codesign --force --sign - "$app"
cp "$src/install.command" "$out/"
