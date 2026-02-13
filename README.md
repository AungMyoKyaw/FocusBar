# FocusBar

A macOS menu bar Pomodoro timer application with gamification and Apple Reminders integration.

[![Build](https://github.com/aungmyokyaw/FocusBar/actions/workflows/build.yml/badge.svg)](https://github.com/aungmyokyaw/FocusBar/actions/workflows/build.yml)
[![Release](https://github.com/aungmyokyaw/FocusBar/actions/workflows/release.yml/badge.svg)](https://github.com/aungmyokyaw/FocusBar/actions/workflows/release.yml)

## Features

- 🍅 Pomodoro timer in the menu bar
- 🎮 Gamification system with XP and achievements
- 📊 Statistics tracking and visualization
- 🔔 Apple Reminders integration
- 🔄 Daily streak tracking

## Requirements

- macOS 13.0+ (Ventura)
- Xcode 15.0+

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
   - Build the app using Xcode
   - Apply ad-hoc code signing
   - Create a GitHub Release with the built artifact
   - Include automatic release notes from commit history

### Tag Format

- Regular releases: `v1.0.0`, `v1.2.3`
- Pre-releases: `v1.0.0-alpha1`, `v1.0.0-beta1`

## License

MIT
