# FocusBar - Agent Documentation

A macOS menu bar application built with SwiftUI and SwiftData.

## Project Overview

- **Type**: Native macOS application
- **Framework**: SwiftUI
- **Persistence**: SwiftData
- **Platform**: macOS 26.2+
- **Language**: Swift 5.0
- **Created with**: Xcode 26.2

## Essential Commands

### Build
```bash
xcodebuild -project FocusBar.xcodeproj -scheme FocusBar -configuration Debug build
```

### Run Tests
```bash
# Unit tests
xcodebuild test -project FocusBar.xcodeproj -scheme FocusBar -destination 'platform=macOS' -only-testing:FocusBarTests

# UI tests
xcodebuild test -project FocusBar.xcodeproj -scheme FocusBar -destination 'platform=macOS' -only-testing:FocusBarUITests
```

### Clean
```bash
xcodebuild -project FocusBar.xcodeproj -scheme FocusBar clean
```

## Project Structure

```
FocusBar/
├── FocusBar/                    # Main app target
│   ├── FocusBarApp.swift        # App entry point (@main)
│   ├── ContentView.swift        # Main view with NavigationSplitView
│   ├── Item.swift               # SwiftData model
│   └── Assets.xcassets/         # Asset catalog (app icon, colors)
├── FocusBarTests/               # Unit tests (Swift Testing framework)
│   └── FocusBarTests.swift
├── FocusBarUITests/             # UI tests (XCTest)
│   ├── FocusBarUITests.swift
│   └── FocusBarUITestsLaunchTests.swift
└── FocusBar.xcodeproj/          # Xcode project configuration
```

## Build Targets

| Target | Type | Description |
|--------|------|-------------|
| FocusBar | App | Main macOS application |
| FocusBarTests | Unit Test | Uses Swift Testing framework (`@Test`, `#expect`) |
| FocusBarUITests | UI Test | Uses XCTest framework for UI automation |

## Code Patterns

### App Architecture
- Uses SwiftUI `@main` attribute for app entry point
- SwiftData `ModelContainer` configured in app struct
- `@Model` macro for data models
- `@Query` property wrapper for fetching data
- `@Environment(\.modelContext)` for database context

### Data Model Pattern
```swift
@Model
final class Item {
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
```

### View Pattern
- Views are SwiftUI structs conforming to `View` protocol
- Use `#Preview` macro for SwiftUI previews (not `PreviewProvider`)
- Previews include `.modelContainer(for: Item.self, inMemory: true)` for SwiftData

### Testing Patterns

**Unit Tests** (FocusBarTests):
- Uses Swift Testing framework
- `@Test` attribute for test functions
- `#expect(...)` for assertions
- `@@testable import FocusBar` to access app code

**UI Tests** (FocusBarUITests):
- Uses XCTest framework
- `XCTestCase` subclass
- `XCUIApplication()` for app automation
- `@MainActor` for UI test methods

## Configuration

### Bundle Identifiers
- App: `aungmyokyaw.com.FocusBar`
- Unit Tests: `aungmyokyaw.com.FocusBarTests`
- UI Tests: `aungmyokyaw.com.FocusBarUITests`

### Build Settings
- App Sandbox: Enabled
- User Selected Files: Read-only
- SwiftUI Previews: Enabled
- Code Signing: Automatic
- Swift Concurrency: `MainActor` default isolation

## Naming Conventions

- Files: PascalCase matching the struct/class name (e.g., `ContentView.swift`, `FocusBarApp.swift`)
- Views: PascalCase with descriptive names (e.g., `ContentView`)
- Models: PascalCase nouns (e.g., `Item`)
- Test files: Match target name pattern (e.g., `FocusBarTests.swift`)

## Gotchas

1. **Xcode 26.2 Required**: This project uses Xcode 26.2 features including:
   - `objectVersion = 77` project format
   - `PBXFileSystemSynchronizedRootGroup` for file management
   - Swift Testing framework

2. **SwiftData Import Order**: Both `SwiftUI` and `SwiftData` imports are needed when using `@Model` and `@Query`

3. **ModelContainer Setup**: Must be configured before views that use `@Query`

4. **Test Framework Split**: Unit tests use Swift Testing, UI tests use XCTest - don't mix the APIs

5. **macOS Deployment Target**: Set to 26.2, requires the latest macOS version
