# MScroll

MScroll is a lightweight native macOS menu-bar utility that reverses conventional mouse-wheel scrolling while leaving trackpad scrolling unchanged.

## Requirements

- macOS 13 or newer
- Apple Swift toolchain (included with Xcode or Xcode Command Line Tools)

## Build and test

```sh
./scripts/test.sh
./scripts/build-app.sh
```

The packaged application is written to `.build/MScroll.app`.

The source icon is kept in `assets/MScroll.png`. The packaging script generates the required macOS icon sizes and embeds them as `AppIcon.icns`.

## Install

1. Build the application.
2. Move `.build/MScroll.app` into `/Applications`.
3. Open MScroll.
4. Grant Accessibility permission when macOS requests it.

MScroll registers itself to launch at login on first run. You can change that behavior from its menu-bar menu.

## How it works

Trackpads normally produce continuous, pixel-based scroll events. Conventional mouse wheels normally produce line-based events. MScroll reverses the latter and leaves the former unchanged.

Magic Mouse scrolling is continuous and is therefore treated like trackpad scrolling in this version.
