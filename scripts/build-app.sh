#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
repo_root=${script_dir:h}
configuration=${1:-release}
app_path="$repo_root/.build/MScroll.app"

cd "$repo_root"
swift build -c "$configuration"
binary_dir=$(swift build -c "$configuration" --show-bin-path)

if [[ "$app_path" != "$repo_root/.build/MScroll.app" ]]; then
    print -u2 "Unexpected application output path"
    exit 1
fi

rm -rf "$app_path"
mkdir -p "$app_path/Contents/MacOS"
cp "$binary_dir/MScroll" "$app_path/Contents/MacOS/MScroll"
cp "$repo_root/Packaging/Info.plist" "$app_path/Contents/Info.plist"
codesign --force --sign - "$app_path"

print "$app_path"
