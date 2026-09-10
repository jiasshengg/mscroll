#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
repo_root=${script_dir:h}
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$repo_root/Packaging/Info.plist")
architecture=$(uname -m)
app_path="$repo_root/.build/MScroll.app"
dmg_path="$repo_root/.build/MScroll-$version-$architecture.dmg"
staging_dir=$(mktemp -d)
trap 'rm -rf "$staging_dir"' EXIT

"$repo_root/scripts/build-app.sh"

cp -R "$app_path" "$staging_dir/MScroll.app"
ln -s /Applications "$staging_dir/Applications"

hdiutil create \
    -volname "MScroll" \
    -srcfolder "$staging_dir" \
    -format UDZO \
    -ov \
    "$dmg_path"

print "$dmg_path"
