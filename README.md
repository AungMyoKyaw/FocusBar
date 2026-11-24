# FocusBar

Native macOS menu bar Pomodoro timer with SwiftData statistics, XP progression, and Apple Reminders integration.

[![Build](https://github.com/AungMyoKyaw/FocusBar/actions/workflows/build.yml/badge.svg)](https://github.com/AungMyoKyaw/FocusBar/actions/workflows/build.yml)
[![Release](https://github.com/AungMyoKyaw/FocusBar/actions/workflows/release.yml/badge.svg)](https://github.com/AungMyoKyaw/FocusBar/actions/workflows/release.yml)

## Features

- Menu bar timer with countdown text, progress bar, or icon-only display modes
- Date-based timer state that survives system sleep and wake
- Apple Reminders picker for linking focus sessions and logging focus time
- Swift Charts dashboard for hourly focus distribution and time by task
- 30-level XP progression, 20 achievements, and daily streaks with weekly freezes
- Optional Launch at Login, optional auto-start for the next session, and JSON export

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0+ (for building from source)

## Installation

### Homebrew

```bash
brew install --cask aungmyokyaw/tap/focusbar
```

### Direct Download

Download `FocusBar.app.zip` from [GitHub Releases](https://github.com/AungMyoKyaw/FocusBar/releases), extract it, and move `FocusBar.app` to `/Applications`.

## Development

```bash
# Build
xcodebuild -project FocusBar.xcodeproj -scheme FocusBar -configuration Debug build

# Unit tests
xcodebuild test -project FocusBar.xcodeproj -scheme FocusBar -destination 'platform=macOS' -only-testing:FocusBarTests

# UI tests
xcodebuild test -project FocusBar.xcodeproj -scheme FocusBar -destination 'platform=macOS' -only-testing:FocusBarUITests
```

## Release Process

Push a version tag (`v1.1.0`, `v1.0.0-beta1`) to trigger the GitHub Actions release workflow, which runs `FocusBarTests`, builds a universal (`arm64` + `x86_64`) app bundle, applies ad-hoc code signing, and publishes `FocusBar.app.zip`.

## License

[MIT](LICENSE)
