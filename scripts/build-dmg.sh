#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
repo_root=${script_dir:h}
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$repo_root/Packaging/Info.plist")
architecture=$(uname -m)
app_path="$repo_root/.build/Glide.app"
dmg_path="$repo_root/.build/Glide-$version-$architecture.dmg"

if hdiutil info | /usr/bin/grep -Fq "image-path      : $dmg_path"; then
    print -u2 "Eject the currently mounted Glide DMG before rebuilding it"
    exit 1
fi

staging_dir=$(mktemp -d)
temporary_dmg="$staging_dir/Glide-rw.dmg"
mount_path="$staging_dir/mount"
device=""

cleanup() {
    if [[ -n "$device" ]]; then
        hdiutil detach "$device" -quiet || true
    fi
    rm -rf "$staging_dir"
}

trap cleanup EXIT

"$repo_root/scripts/build-app.sh"
"$repo_root/scripts/render-dmg-background.swift" \
    "$repo_root/assets/DMGBackgroundBase.png" \
    "$repo_root/assets/DMGBackground.png"

mkdir -p "$staging_dir/contents/.background" "$mount_path"
cp -R "$app_path" "$staging_dir/contents/Glide.app"
cp "$repo_root/assets/DMGBackground.png" "$staging_dir/contents/.background/DMGBackground.png"
ln -s /Applications "$staging_dir/contents/Applications"

hdiutil create \
    -volname "Glide" \
    -srcfolder "$staging_dir/contents" \
    -format UDRW \
    -ov "$temporary_dmg" >/dev/null

device=$(hdiutil attach "$temporary_dmg" \
    -readwrite \
    -noverify \
    -noautoopen \
    -mountpoint "$mount_path" | awk '/^\/dev\// { print $1; exit }')

sleep 5

osascript <<APPLESCRIPT
set mountedVolume to POSIX file "$mount_path" as alias
tell application "Finder"
    set installerDisk to disk of mountedVolume
    set backgroundFile to file ".background:DMGBackground.png" of installerDisk
    tell installerDisk
        open
        tell container window
            set current view to icon view
            set toolbar visible to false
            set statusbar visible to false
            set pathbar visible to false
            set bounds to {100, 100, 760, 520}
        end tell
        tell icon view options of container window
            set arrangement to not arranged
            set icon size to 128
            set text size to 14
            set background picture to backgroundFile
        end tell
        set position of item "Glide.app" of container window to {170, 230}
        set position of item "Applications" of container window to {490, 230}
        close container window
        open
        delay 1
        set bounds of container window to {100, 100, 750, 510}
        delay 1
        set bounds of container window to {100, 100, 760, 520}
        delay 3
        close container window
    end tell
end tell
APPLESCRIPT

for attempt in {1..40}; do
    if [[ -f "$mount_path/.DS_Store" ]] && \
        /usr/bin/grep -a -q "backgroundImageAlias" "$mount_path/.DS_Store"; then
        break
    fi
    sleep 0.25
done

if [[ ! -f "$mount_path/.DS_Store" ]] || \
    ! /usr/bin/grep -a -q "backgroundImageAlias" "$mount_path/.DS_Store"; then
    print -u2 "Finder did not save the DMG window layout"
    exit 1
fi

sync
hdiutil detach "$device" -quiet
device=""

hdiutil convert "$temporary_dmg" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov \
    -o "$dmg_path" >/dev/null

print "$dmg_path"
