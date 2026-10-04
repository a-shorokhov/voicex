#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
configuration="${1:-release}"
app="$PWD/build/Voicex.app"
swift package resolve --scratch-path build/spm
if [[ "$(xcode-select -p)" == *CommandLineTools* ]]; then
    recorder="$PWD/build/spm/checkouts/KeyboardShortcuts/Sources/KeyboardShortcuts/Recorder.swift"
    chmod u+w "$recorder"
    # CLT lacks Apple's Preview macro plugin. Only strip design-time declarations
    # from the disposable dependency checkout; do not modify runtime SDK code.
    if rg -q '^#Preview' "$recorder"; then perl -0777 -i -pe 's/^#Preview \{.*?^\}//msg' "$recorder"; fi
fi
# SwiftPM's resource accessor assumes a CLI layout. In this disposable checkout,
# resolve the bundle inside Contents/Resources first, retaining the CLI fallback.
utilities="$PWD/build/spm/checkouts/KeyboardShortcuts/Sources/KeyboardShortcuts/Utilities.swift"
chmod u+w "$utilities"
if rg -q 'bundle: \.module' "$utilities"; then perl -i -pe 's/bundle: \.module/bundle: Bundle.main.url(forResource: "KeyboardShortcuts_KeyboardShortcuts", withExtension: "bundle").flatMap { Bundle(url: \$0) } ?? .module/' "$utilities"; fi
swift build --scratch-path build/spm -c "$configuration" --arch arm64
binary_dir=$(swift build --scratch-path build/spm -c "$configuration" --arch arm64 --show-bin-path)
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$binary_dir/Voicex" "$app/Contents/MacOS/Voicex"
cp Info.plist "$app/Contents/Info.plist"
for bundle in "$binary_dir"/*.bundle(N); do
    rm -rf "$app/${bundle:t}" "$app/Contents/Resources/${bundle:t}"
    cp -R "$bundle" "$app/Contents/Resources/"
done
codesign --force --sign - "$app"
echo "$app"
