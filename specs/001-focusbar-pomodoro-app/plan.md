# Implementation Plan: FocusBar — macOS Menu Bar Pomodoro Timer

**Branch**: `001-focusbar-pomodoro-app` | **Date**: 2026-02-14 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-focusbar-pomodoro-app/spec.md`

## Summary

Build a native macOS menu bar Pomodoro timer using SwiftUI and SwiftData. The app lives exclusively in the menu bar (no Dock icon), provides one-click focus sessions with automatic work/break cycling, integrates optionally with Apple Reminders via EventKit, and includes a full gamification system (XP, levels, streaks, 20+ achievements). All data is local-first with zero network activity.

## Technical Context

**Language/Version**: Swift 5.9+  
**Primary Dependencies**: SwiftUI, SwiftData, EventKit, UserNotifications  
**Storage**: SwiftData (sessions, achievements, daily stats) + UserDefaults (preferences, XP, level, streak)  
**Testing**: Swift Testing framework (`@Test`, `#expect`) for unit tests, XCTest for UI tests  
**Target Platform**: macOS 13.0+ (Ventura) — MenuBarExtra requires macOS 13  
**Project Type**: Single native macOS application  
**Performance Goals**: <500ms launch, <50MB idle memory, ±1s timer accuracy over 25 min, <0.5% battery/hr  
**Constraints**: App Sandbox, no network access, optional EventKit + UserNotifications permissions  
**Scale/Scope**: Single-user local app, ~15 views, 3 SwiftData models, 5 services

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The project constitution is a blank template with no project-specific gates defined. No violations exist. Proceeding to Phase 0.

**Post-Phase 1 re-check**: No constitution violations. The design uses standard SwiftUI/SwiftData patterns with minimal complexity.

## Project Structure

### Documentation (this feature)

```text
specs/001-focusbar-pomodoro-app/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (internal service contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
FocusBar/
├── App/
│   └── FocusBarApp.swift            # @main, ModelContainer, MenuBarExtra
├── Models/
│   ├── Session.swift                # @Model — focus/break session record
│   ├── Achievement.swift            # @Model — unlocked achievements
│   ├── DailyStats.swift             # @Model — daily aggregates
│   └── SessionType.swift            # Enum: pomodoro, shortBreak, longBreak
├── ViewModels/
│   ├── TimerViewModel.swift         # Timer state, countdown, session cycling
│   ├── GamificationViewModel.swift  # XP, levels, streaks, achievements
│   ├── StatsViewModel.swift         # Statistics queries and aggregation
│   ├── SettingsViewModel.swift      # Preferences binding
│   └── RemindersViewModel.swift     # EventKit integration
├── Views/
│   ├── MenuBar/
│   │   ├── MenuBarView.swift        # Main menu bar dropdown content
│   │   └── TimerDisplayView.swift   # Countdown / progress bar in menu bar
│   ├── Settings/
│   │   └── SettingsView.swift       # Preferences window
│   ├── Stats/
│   │   ├── StatsView.swift          # Statistics dashboard
│   │   └── ChartViews.swift         # Focus pattern charts
│   ├── Achievements/
│   │   └── AchievementsView.swift   # Achievements panel
│   └── Components/
│       ├── ReminderPicker.swift     # Searchable reminder dropdown
│       └── XPProgressView.swift     # XP bar and level indicator
├── Services/
│   ├── TimerService.swift           # Monotonic clock, sleep/wake handling
│   ├── GamificationService.swift    # XP calculation, achievement evaluation
│   ├── NotificationService.swift    # UserNotifications wrapper
│   ├── ReminderService.swift        # EventKit wrapper
│   ├── ExportService.swift          # JSON export
│   └── StreakService.swift          # Daily streak logic, freeze management
├── Utilities/
│   ├── Constants.swift              # XP tables, achievement definitions, defaults
│   └── UserDefaultsKeys.swift       # Type-safe UserDefaults keys
└── Resources/
    ├── Assets.xcassets/             # App icon, colors, SF Symbols
    └── Sounds/                      # Notification sound files

FocusBarTests/
├── TimerServiceTests.swift
├── GamificationServiceTests.swift
├── StreakServiceTests.swift
├── AchievementTests.swift
└── ExportServiceTests.swift

FocusBarUITests/
├── FocusBarUITests.swift
└── FocusBarUITestsLaunchTests.swift
```

**Structure Decision**: Single native macOS app. Views organized by feature area (MenuBar, Settings, Stats, Achievements). Services encapsulate business logic independent of UI. ViewModels bridge services to views using `@Observable`. Models use SwiftData `@Model` macro.
