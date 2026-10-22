#!/bin/sh
# Builds launcher.app for Apple silicon Macs with macOS 15 or later into a
# game folder. Needs rsvg-convert (brew install librsvg).
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

# The icon is the transparent Allied Assault star. Build every size the
# .icns needs so Finder does not fall back to a generic app icon.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
master="$tmp/icon.png"
rsvg-convert -w 1024 -h 1024 "$src/mohaa-transparent.svg" -o "$master"
iconset="$tmp/AppIcon.iconset"
mkdir -p "$iconset"
sips -z 16 16     "$master" --out "$iconset/icon_16x16.png" >/dev/null
sips -z 32 32     "$master" --out "$iconset/icon_16x16@2x.png" >/dev/null
cp "$iconset/icon_16x16@2x.png" "$iconset/icon_32x32.png"
sips -z 64 64     "$master" --out "$iconset/icon_32x32@2x.png" >/dev/null
sips -z 128 128   "$master" --out "$iconset/icon_128x128.png" >/dev/null
sips -z 256 256   "$master" --out "$iconset/icon_128x128@2x.png" >/dev/null
cp "$iconset/icon_128x128@2x.png" "$iconset/icon_256x256.png"
sips -z 512 512   "$master" --out "$iconset/icon_256x256@2x.png" >/dev/null
cp "$iconset/icon_256x256@2x.png" "$iconset/icon_512x512.png"
sips -z 1024 1024 "$master" --out "$iconset/icon_512x512@2x.png" >/dev/null
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"

# Game buttons: the Allied star, the Spearhead chevrons, the Breakthrough dagger.
rsvg-convert -w 64 -h 64 "$src/mohaa-transparent.svg" -o "$app/Contents/Resources/game-aa.png"
rsvg-convert -w 64 -h 64 "$src/mohaa-spearhead.svg" -o "$app/Contents/Resources/game-sh.png"
rsvg-convert -w 64 -h 64 "$src/mohaa-breakthrough.svg" -o "$app/Contents/Resources/game-bt.png"

codesign --force --sign - "$app"
