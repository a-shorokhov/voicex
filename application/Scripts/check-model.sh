#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
Scripts/build-preview.sh release
bin_dir=$(swift build --scratch-path build/spm -c release --show-bin-path)
xcrun swiftc -parse-as-library -swift-version 5 -target arm64-apple-macos14.0 -I "$bin_dir/Modules" -module-cache-path "$PWD/build/module-cache" Sources/SpeechService.swift Checks/ModelChecks.swift "$bin_dir"/ArgmaxCore.build/*.o "$bin_dir"/WhisperKit.build/*.o -o build/model-checks
./build/model-checks "$@"
