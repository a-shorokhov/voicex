#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/module-cache
xcrun swiftc -parse-as-library -swift-version 5 -target arm64-apple-macos14.0 -module-cache-path "$PWD/build/module-cache" Sources/SessionState.swift Sources/PasteService.swift Checks/PreviewStateChecks.swift -o build/state-checks
./build/state-checks
