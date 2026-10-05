#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
source_app="$PWD/build/Voicex.app"
target_app="/Applications/Voicex.app"
if pgrep -x Voicex >/dev/null; then
    print -u2 'Сначала завершите Voicex через меню «Выйти» или ⌘Q. Закрытия окна недостаточно.'
    exit 1
fi
codesign --verify --deep --strict "$source_app"
if [[ -e "$target_app" ]]; then
    installed_id=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$target_app/Contents/Info.plist")
    [[ "$installed_id" == io.github.a-shorokhov.voicex ]] || { print -u2 'В целевой папке другое приложение; установка остановлена.'; exit 1; }
fi
stage=$(mktemp -d /Applications/.voicex-install.XXXXXX)
# Stage a whole bundle on the same volume. Never overwrite a running executable.
trap 'if [[ ! -e "$target_app" && -e "$stage/previous.app" ]]; then mv "$stage/previous.app" "$target_app"; fi; rm -rf "$stage"' EXIT
ditto "$source_app" "$stage/Voicex.app"
codesign --verify --deep --strict "$stage/Voicex.app"
if [[ -e "$target_app" ]]; then mv "$target_app" "$stage/previous.app"; fi
mv "$stage/Voicex.app" "$target_app"
# Refresh only this bundle's registration, including its Finder/Dock icon.
registrar=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
if [[ -x "$registrar" ]]; then "$registrar" -f "$target_app"; fi
print 'Установлено /Applications/Voicex.app. Запустите приложение оттуда; системные разрешения выдаются вручную.'
