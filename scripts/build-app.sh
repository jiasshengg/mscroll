#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
repo_root=${script_dir:h}
configuration=${1:-release}
app_path="$repo_root/.build/MScroll.app"
temporary_dir=$(mktemp -d)
iconset_path="$temporary_dir/AppIcon.iconset"
trap 'rm -rf "$temporary_dir"' EXIT

cd "$repo_root"
swift build -c "$configuration"
binary_dir=$(swift build -c "$configuration" --show-bin-path)

if [[ "$app_path" != "$repo_root/.build/MScroll.app" ]]; then
    print -u2 "Unexpected application output path"
    exit 1
fi

rm -rf "$app_path"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources" "$iconset_path"
cp "$binary_dir/MScroll" "$app_path/Contents/MacOS/MScroll"
cp "$repo_root/Packaging/Info.plist" "$app_path/Contents/Info.plist"

render_icon() {
    local size=$1
    local filename=$2
    sips -z "$size" "$size" "$repo_root/assets/MScroll.png" --out "$iconset_path/$filename" >/dev/null
}

render_icon 16 icon_16x16.png
render_icon 32 icon_16x16@2x.png
render_icon 32 icon_32x32.png
render_icon 64 icon_32x32@2x.png
render_icon 128 icon_128x128.png
render_icon 256 icon_128x128@2x.png
render_icon 256 icon_256x256.png
render_icon 512 icon_256x256@2x.png
render_icon 512 icon_512x512.png
render_icon 1024 icon_512x512@2x.png
iconutil -c icns "$iconset_path" -o "$app_path/Contents/Resources/AppIcon.icns"

codesign --force --sign - "$app_path"

print "$app_path"
