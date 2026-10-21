#!/bin/sh
# Lets macOS run the downloaded game in place: clears the download
# quarantine from everything in this folder.
cd "$(dirname "$0")" && xattr -dr com.apple.quarantine .
