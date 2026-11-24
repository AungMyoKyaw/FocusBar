# FocusBar Agent Documentation

Native macOS menu bar Pomodoro timer with SwiftData persistence, XP/streak tracking, and Apple Reminders integration.

## Overview

- **Type**: Menu bar app (`LSUIElement = YES`, no Dock icon)
- **Framework**: SwiftUI (`MenuBarExtra`, `Swift Charts`), SwiftData, EventKit, ServiceManagement
- **Platform**: macOS 14.0+ (Sonoma), Swift 5.9+ (`MainActor` default isolation)
- **Architecture**: MVVM with a Service layer and `DESIGN.md` visual system

## Commands

```bash
# Debug build
xcodebuild -project FocusBar.xcodeproj -scheme FocusBar -configuration Debug build

# Unit tests (Swift Testing)
xcodebuild test -project FocusBar.xcodeproj -scheme FocusBar -destination 'platform=macOS' -only-testing:FocusBarTests

# UI tests (XCTest)
xcodebuild test -project FocusBar.xcodeproj -scheme FocusBar -destination 'platform=macOS' -only-testing:FocusBarUITests
```

## Project Structure

- `DESIGN.md`: Visual system tokens, typography, and accessibility rules (Surface Mode: `Operate`).
- `FocusBar/App/FocusBarApp.swift`: `@main`, `FocusBarAppDelegate` first-launch onboarding window, `MenuBarExtra`, `ModelContainer`, and window scenes.
- `FocusBar/Models/`: SwiftData `@Model` types (`Session`, `DailyStats`, `Achievement`), `SessionType`, and `AppError`.
- `FocusBar/ViewModels/`: `@Observable` view models (`TimerViewModel`, `GamificationViewModel`, `StatsViewModel`, `SettingsViewModel`, `RemindersViewModel`, `OnboardingViewModel`).
- `FocusBar/Services/`: `TimerService`, `GamificationService`, `StreakService`, `NotificationService`, `ReminderService`, `ExportService`, `LoggingService`.
- `FocusBar/Utilities/`: `Constants`, `UserDefaultsKeys`, `FocusBarTheme`.
- `FocusBar/Views/`: `MenuBar/`, `Settings/`, `Stats/`, `Achievements/`, `Onboarding/`, `Components/`.
- `FocusBarTests/`: Swift Testing unit tests (`@Test`, `#expect`).
- `FocusBarUITests/`: XCTest UI tests.

## Gotchas

1. **Menu Bar Label**: `MenuBarExtra` uses `TimerDisplayView` reading `TimerViewModel` (`menuBarSystemImage`, `menuBarTitle`, `sessionProgress`).
2. **SwiftData + `@AppStorage` Split**: Structured records live in SwiftData; scalar progress and preferences live in `UserDefaults`.
3. **EventKit Lazy Auth**: Reminders permission is requested only when the user taps Connect Apple Reminders or during onboarding; use `#available(macOS 14, *)` for `.fullAccess`.
4. **Timer Accuracy**: Uses `Date`-based elapsed time with `NSWorkspace` sleep/wake observers (removed in `deinit` from `NSWorkspace.shared.notificationCenter`) and a 300ms debounce guard.
5. **Xcode File Sync**: Project uses `PBXFileSystemSynchronizedRootGroup` on `FocusBar/`; files added inside `FocusBar/` are auto-included in the app target.
6. **Onboarding Window**: `FocusBarAppDelegate` opens an `NSWindow` on `applicationDidFinishLaunching` when `hasCompletedOnboarding` is false, so first-launch users see it without clicking the menu bar icon first.
