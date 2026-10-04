#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
app="$PWD/build/Voicex.app"
mkdir -p "$app/Contents/MacOS" "$PWD/build/module-cache"
xcrun swiftc -parse-as-library -swift-version 5 -target arm64-apple-macos14.0 -module-cache-path "$PWD/build/module-cache" Sources/*.swift -o "$app/Contents/MacOS/Voicex"
cp Info.plist "$app/Contents/Info.plist"
codesign --force --sign - "$app"
echo "$app"
