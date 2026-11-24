# FocusBar

A native macOS menu bar Pomodoro timer application with gamification and Apple Reminders integration.

[![Build](https://github.com/AungMyoKyaw/FocusBar/actions/workflows/build.yml/badge.svg)](https://github.com/AungMyoKyaw/FocusBar/actions/workflows/build.yml)
[![Release](https://github.com/AungMyoKyaw/FocusBar/actions/workflows/release.yml/badge.svg)](https://github.com/AungMyoKyaw/FocusBar/actions/workflows/release.yml)

## Features

- 🍅 Pomodoro timer in the menu bar (countdown text, progress bar, or icon-only modes)
- 🎮 Gamification system with XP, 30 levels, and 20 achievements
- 📊 Statistics tracking and visualization with Swift Charts
- 🔔 Apple Reminders integration (search, quick-add, and log focus time)
- 🔄 Daily streak tracking with weekly streak freezes
- 🚀 Launch at Login & optional auto-start next session

## Requirements

- macOS 14.0+ (Sonoma)
- Xcode 15.0+ (for building from source)

## Installation

### Homebrew

```bash
brew install --cask aungmyokyaw/tap/focusbar
```

### Direct Download

Download `FocusBar.app.zip` from the [GitHub Releases](https://github.com/AungMyoKyaw/FocusBar/releases) page, unzip it, and drag `FocusBar.app` to `/Applications`.

## Development

### Building

```bash
xcodebuild -project FocusBar.xcodeproj -scheme FocusBar -configuration Debug build
```

### Running Tests

```bash
# Unit tests
xcodebuild test -project FocusBar.xcodeproj -scheme FocusBar -destination 'platform=macOS' -only-testing:FocusBarTests

# UI tests
xcodebuild test -project FocusBar.xcodeproj -scheme FocusBar -destination 'platform=macOS' -only-testing:FocusBarUITests
```

## Release Process

Releases are automated using GitHub Actions. To create a new release:

1. Create and push a version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. The workflow will:
   - Run `FocusBarTests`
   - Build a Universal binary (`arm64` + `x86_64`) using Xcode
   - Apply ad-hoc code signing
   - Package `FocusBar.app.zip` and publish a GitHub Release with release notes

## License

[MIT](LICENSE)
