#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
Scripts/build-release.sh
stage=$(mktemp -d "$PWD/build/dmg-stage.XXXXXX")
trap 'rm -rf "$stage"' EXIT
ditto build/Voicex.app "$stage/Voicex.app"
ln -s /Applications "$stage/Applications"
cp NOTICES.md "$stage/"
mkdir -p build/release
hdiutil create -ov -volname Voicex -srcfolder "$stage" -format UDZO build/release/Voicex-macos-arm64.dmg
(cd build/release && shasum -a 256 Voicex-macos-arm64.dmg > SHA256SUMS.txt)
