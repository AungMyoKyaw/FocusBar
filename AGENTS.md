# FocusBar - Agent Documentation

A macOS menu bar Pomodoro timer with gamification and Apple Reminders integration.

## Project Overview

- **Type**: Native macOS menu bar application (no Dock icon)
- **Framework**: SwiftUI (MenuBarExtra, Swift Charts)
- **Persistence**: SwiftData + UserDefaults (@AppStorage)
- **Integrations**: EventKit (Apple Reminders), UserNotifications
- **Platform**: macOS 13.0+ (Ventura)
- **Language**: Swift 5.9+
- **Architecture**: MVVM with Service layer

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
├── App/
│   └── FocusBarApp.swift              # @main, MenuBarExtra, ModelContainer, Window scenes
├── Models/
│   ├── AppError.swift                # Error enum: dataError, permissionDenied, exportFailed, unknown
│   ├── Session.swift                  # @Model — focus/break session record
│   ├── Achievement.swift              # @Model — unlocked achievements
│   ├── DailyStats.swift               # @Model — daily aggregates
│   └── SessionType.swift              # Enum: pomodoro, shortBreak, longBreak
├── ViewModels/
│   ├── TimerViewModel.swift           # Timer state, countdown, session lifecycle
│   ├── GamificationViewModel.swift    # XP, levels, streaks, achievements
│   ├── StatsViewModel.swift           # Statistics queries and aggregation
│   ├── SettingsViewModel.swift        # @AppStorage preferences binding
│   ├── RemindersViewModel.swift       # EventKit integration
│   └── OnboardingViewModel.swift      # Onboarding flow state, permission requests
├── Views/
│   ├── MenuBar/
│   │   ├── MenuBarView.swift          # Main dropdown: timer, controls, XP, navigation
│   │   └── TimerDisplayView.swift     # Menu bar label: countdown / progress bar / icon
│   ├── Settings/
│   │   └── SettingsView.swift         # Tabbed preferences + data export + About tab
│   ├── Stats/
│   │   ├── StatsView.swift            # Statistics dashboard with summary cards
│   │   └── ChartViews.swift           # Swift Charts: focus by hour, task breakdown
│   ├── Achievements/
│   │   └── AchievementsView.swift     # Achievement grid grouped by category
│   └── Components/
│       ├── ReminderPicker.swift       # Searchable reminder dropdown + quick add
│       ├── XPProgressView.swift       # XP bar, level badge, streak counter
│       └── ErrorBannerView.swift      # Auto-dismiss error banner (5s)
├── Services/
│   ├── TimerService.swift             # Date-based timer, sleep/wake handling, 300ms debounce
│   ├── GamificationService.swift      # XP calculation, achievement evaluation
│   ├── NotificationService.swift      # UNUserNotificationCenter wrapper
│   ├── ReminderService.swift          # EventKit wrapper (lazy auth, #available deprecation fix)
│   ├── ExportService.swift            # JSON export with NSSavePanel
│   ├── StreakService.swift            # Daily streak logic, freeze management
│   └── LoggingService.swift           # OSLog Logger with 6 categories
├── Utilities/
│   ├── Constants.swift                # 30-level XP table, 20 achievement definitions, app metadata
│   └── UserDefaultsKeys.swift         # Type-safe keys + MenuBarDisplayMode enum + hasCompletedOnboarding
├── Resources/
│   ├── Assets.xcassets/               # App icon, accent color
│   └── Sounds/                        # Notification sound files
├── Views/Onboarding/
│   ├── OnboardingContainerView.swift  # Step indicator + navigation (480×560 window)
│   ├── WelcomeStepView.swift          # Step 1: app intro, feature highlights
│   ├── PermissionsStepView.swift      # Step 2: notification/reminder permissions
│   └── ReadyStepView.swift            # Step 3: summary + Get Started
└── FocusBar.entitlements              # Sandbox + Reminders permission

FocusBarTests/                         # Unit tests (Swift Testing framework)
FocusBarUITests/                       # UI tests (XCTest)

specs/001-focusbar-pomodoro-app/       # Feature specification artifacts
├── spec.md                            # Feature specification (8 user stories)
├── plan.md                            # Implementation plan
├── research.md                        # Technical decisions (9 research items)
├── data-model.md                      # Entity definitions, XP/achievement tables
├── contracts/services.md              # Service protocol contracts
├── quickstart.md                      # Development setup guide
├── tasks.md                           # 57 implementation tasks (all complete)
└── checklists/requirements.md         # Quality checklist (16/16 pass)

specs/003-launch-readiness/            # Launch readiness feature spec
├── spec.md                            # 3 user stories (onboarding, errors, accessibility)
├── plan.md                            # Architecture & file structure
├── research.md                        # 9 research items (OSLog, AppError, etc.)
├── data-model.md                      # State definitions (no new SwiftData models)
├── contracts/services.md              # Updated service contracts
├── quickstart.md                      # Build/test commands
├── tasks.md                           # 33 tasks in 5 phases
└── checklists/requirements.md         # Quality checklist
```

## Build Targets

| Target | Type | Description |
|--------|------|-------------|
| FocusBar | App | Menu bar Pomodoro timer (LSUIElement=true) |
| FocusBarTests | Unit Test | Swift Testing framework (`@Test`, `#expect`) |
| FocusBarUITests | UI Test | XCTest framework for UI automation |

## Code Patterns

### App Architecture
- Menu-bar-only app via `MenuBarExtra` with `.menuBarExtraStyle(.window)`
- `LSUIElement = true` hides Dock icon
- `@Observable` ViewModels bridge Services to Views
- Services encapsulate business logic, testable without UI
- SwiftData `@Model` for structured data, `@AppStorage` for scalar preferences

### Key Data Models
- **Session**: Timer period (focus/break) with start/end times, XP earned, optional reminder link
- **DailyStats**: Aggregated daily Pomodoros, focus minutes, streak status, XP
- **Achievement**: Milestone unlock with type ID and unlock date

### Timer Architecture
- Date-based elapsed time (not tick counting) for sleep/wake accuracy
- 1-second `Timer` for UI refresh only
- `NSWorkspace.willSleepNotification` / `didWakeNotification` observers
- Automatic session cycling: focus → short break → ... → long break → reset

### Gamification System
- 30 levels (Seedling → Focus Master), XP thresholds in `Constants.levels`
- 20 achievements defined in `Constants.achievements`
- XP formula: `base × streakMultiplier × levelMultiplier + dailyGoalBonus`
- Streak freeze: 1 per ISO week, auto-applied

### Service Contracts
All services have protocol-style interfaces documented in `specs/001-focusbar-pomodoro-app/contracts/services.md`. Updated contracts for error throwing and logging in `specs/003-launch-readiness/contracts/services.md`.

### Logging Architecture
- OSLog `Logger` with subsystem `com.aungmyokyaw.FocusBar` and 6 categories
- Static `LoggingService` enum with `logError`, `logInfo`, `logDebug` methods
- All services log operations at info/debug level, errors at error level

### Error Handling
- `AppError` enum thrown by services, caught at ViewModel boundary
- `ErrorBannerView` displays errors with auto-dismiss (5 seconds)
- ViewModels expose `currentError: AppError?` for banner binding

### Onboarding
- 3-step flow: Welcome → Permissions → Ready
- Standalone `Window` scene (not sheet on MenuBarExtra)
- `OnboardingViewModel` manages step navigation and permission requests
- `@AppStorage("hasCompletedOnboarding")` gate prevents re-showing

### Accessibility
- All interactive elements have `.accessibilityLabel` and `.accessibilityHint`
- Composite elements use `.accessibilityElement(children: .combine)`
- All colors are semantic (`.primary`, `.secondary`, `.green`, `.orange`, `.blue`)

## Configuration

### Bundle Identifier
- App: `aungmyokyaw.com.FocusBar`

### Entitlements
- App Sandbox: Enabled
- Reminders (EventKit): Enabled (optional — app works without it)

### Build Settings
- `INFOPLIST_KEY_LSUIElement = YES` (menu-bar-only)
- `CODE_SIGN_ENTITLEMENTS = FocusBar/FocusBar.entitlements`
- Code Signing: Automatic
- Swift Concurrency: `MainActor` default isolation

## Naming Conventions

- Files: PascalCase matching struct/class name
- Views: `*View.swift` (e.g., `MenuBarView`, `StatsView`)
- ViewModels: `*ViewModel.swift` (e.g., `TimerViewModel`)
- Services: `*Service.swift` (e.g., `TimerService`, `GamificationService`)
- Models: PascalCase nouns (e.g., `Session`, `Achievement`)

## Gotchas

1. **Menu Bar Label**: The `MenuBarExtra` label uses `Text(timerViewModel.menuBarTitle)` for dynamic countdown — this must be a lightweight view
2. **SwiftData + @AppStorage Split**: Structured data (sessions, achievements) in SwiftData; scalar prefs (XP, level, streak) in UserDefaults via `@AppStorage`
3. **EventKit Lazy Auth**: Reminders permission requested only when user first accesses task linking, not at launch
4. **Timer Accuracy**: Uses `Date`-based elapsed time, not tick counting — survives sleep/wake
5. **ModelContainer Setup**: Configured once in `FocusBarApp`, passed to all scenes via `.modelContainer()`. Falls back to in-memory store on creation failure.
6. **Test Framework Split**: Unit tests use Swift Testing (`@Test`, `#expect`), UI tests use XCTest — don't mix
7. **Xcode File Sync**: Project uses `PBXFileSystemSynchronizedRootGroup` — new files in FocusBar/ are auto-included
8. **Onboarding Window**: Opens via `OpenWindowAction` only when `hasCompletedOnboarding` is false. Separate `Window` scene, not a sheet.
9. **EventKit Deprecation**: `EKAuthorizationStatus.authorized` deprecated in macOS 14 — use `#available(macOS 14, *)` branching with `.fullAccess`
10. **Timer Debounce**: 300ms guard via `lastStateChangeDate` on TimerService prevents rapid double-taps
