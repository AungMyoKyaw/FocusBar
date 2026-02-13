# Quickstart: FocusBar Development

**Branch**: `001-focusbar-pomodoro-app` | **Date**: 2026-02-14

## Prerequisites

- **Xcode 15.0+** (for Swift 5.9, SwiftData, Swift Charts)
- **macOS 13.0+ (Ventura)** as both build host and deployment target
- Apple Developer account (free tier sufficient for local development)

## Setup

```bash
# Clone and checkout feature branch
git clone <repository-url>
cd FocusBar
git checkout 001-focusbar-pomodoro-app

# Open in Xcode
open FocusBar.xcodeproj
```

No external dependencies. No package managers (SPM/CocoaPods). Everything uses Apple-native frameworks.

## Build & Run

```bash
# Build from CLI
xcodebuild -project FocusBar.xcodeproj -scheme FocusBar -configuration Debug build

# Run tests
xcodebuild test -project FocusBar.xcodeproj -scheme FocusBar \
  -destination 'platform=macOS' -only-testing:FocusBarTests

# Run UI tests
xcodebuild test -project FocusBar.xcodeproj -scheme FocusBar \
  -destination 'platform=macOS' -only-testing:FocusBarUITests

# Clean
xcodebuild -project FocusBar.xcodeproj -scheme FocusBar clean
```

Or use Xcode: `Cmd+R` to run, `Cmd+U` to test.

## Project Layout

```
FocusBar/
├── App/                    # App entry point (MenuBarExtra, ModelContainer)
├── Models/                 # SwiftData @Model classes + enums
├── ViewModels/             # @Observable classes bridging services ↔ views
├── Views/                  # SwiftUI views organized by feature
│   ├── MenuBar/            # Menu bar dropdown content
│   ├── Settings/           # Preferences window
│   ├── Stats/              # Statistics dashboard + charts
│   ├── Achievements/       # Achievement panel
│   └── Components/         # Reusable components
├── Services/               # Business logic (timer, gamification, EventKit, etc.)
├── Utilities/              # Constants, keys, helpers
└── Resources/              # Assets, sounds
```

## Key Configuration

### Info.plist Additions

```xml
<!-- Hide from Dock (menu-bar-only app) -->
<key>LSUIElement</key>
<true/>
```

### Entitlements

```xml
<!-- App Sandbox (required) -->
<key>com.apple.security.app-sandbox</key>
<true/>

<!-- Apple Reminders access (optional feature) -->
<key>com.apple.security.personal-information.reminders</key>
<true/>
```

## Development Workflow

1. **Models first**: Define SwiftData `@Model` classes in `Models/`
2. **Services next**: Implement business logic in `Services/` with protocol-based design
3. **ViewModels**: Wire services to observable state in `ViewModels/`
4. **Views last**: Build UI in `Views/` consuming ViewModels
5. **Test each layer**: Unit test services independently, integration test ViewModels

## Testing Strategy

- **Unit tests** (Swift Testing): Services and gamification logic — no UI dependency
- **UI tests** (XCTest): Menu bar interaction, settings persistence, timer flow
- **Test data**: Use `inMemory: true` ModelContainer for SwiftData tests

```swift
// Example: In-memory container for testing
let config = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try ModelContainer(for: Session.self, configurations: [config])
```

## Architecture Decisions

| Decision | Choice | Reference |
|----------|--------|-----------|
| Menu bar framework | SwiftUI MenuBarExtra | research.md R1 |
| Timer accuracy | Date-based elapsed time | research.md R2 |
| Persistence | SwiftData + UserDefaults | research.md R3 |
| Reminders | EventKit (lazy auth) | research.md R4 |
| Notifications | UNUserNotificationCenter | research.md R5 |
| Charts | Swift Charts (native) | research.md R7 |
| App lifecycle | LSUIElement + MenuBarExtra only | research.md R9 |
