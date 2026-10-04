#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(xcode-select -p)" != *CommandLineTools* ]]; then
    xcodebuild -project Voicex.xcodeproj -scheme Voicex -configuration Release -derivedDataPath build/DerivedData build
    ditto build/DerivedData/Build/Products/Release/Voicex.app build/Voicex.app
else
    Scripts/build-preview.sh release
fi
mkdir -p build/Voicex.app/Contents/Resources
cp NOTICES.md build/Voicex.app/Contents/Resources/
codesign --force --sign - build/Voicex.app
codesign --verify --deep --strict build/Voicex.app
