#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
Scripts/build-release.sh
stage=$(mktemp -d "$PWD/build/dmg-stage.XXXXXX")
trap 'rm -rf "$stage"' EXIT
ditto build/Voicex.app "$stage/Voicex.app"
ln -s /Applications "$stage/Applications"
cp NOTICES.md "$stage/"
cp INSTALL.txt "$stage/0 — Установка.txt"
mkdir -p build/release
hdiutil create -ov -volname Voicex -srcfolder "$stage" -format UDZO build/release/Voicex-macos-arm64.dmg

# Keep the stable local filename and a versioned download for the website.
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' build/Voicex.app/Contents/Info.plist)
versioned="Voicex-${version}-macos-arm64.dmg"
cp build/release/Voicex-macos-arm64.dmg "build/release/$versioned"
(cd build/release && shasum -a 256 Voicex-macos-arm64.dmg "$versioned" > SHA256SUMS.txt)
python3 - "$PWD/build/release" "$version" "$versioned" "$(git rev-parse HEAD)" <<'PYMETA'
import hashlib, json, sys
from pathlib import Path
folder, version, filename, commit = sys.argv[1:]
p = Path(folder) / filename
metadata = {
    "name": "Voicex", "version": version, "platform": "macOS", "architecture": "arm64",
    "minimumMacOS": "14.0", "filename": filename, "bytes": p.stat().st_size,
    "sha256": hashlib.sha256(p.read_bytes()).hexdigest(), "sourceCommit": commit,
    "signing": "ad-hoc", "notarized": False, "modelIncluded": False,
    "modelDownloadApproxMB": 626,
}
(Path(folder) / "release.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n")
PYMETA
cp RELEASE-HANDOFF.md build/release/
