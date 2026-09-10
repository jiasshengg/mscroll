#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
repo_root=${script_dir:h}
temporary_dir=$(mktemp -d)
trap 'rm -rf "$temporary_dir"' EXIT

cd "$repo_root"
swift build
swiftc \
    -parse-as-library \
    Sources/MScroll/ScrollEventTap.swift \
    Tests/MScrollChecks/main.swift \
    -o "$temporary_dir/MScrollChecks"
"$temporary_dir/MScrollChecks"
