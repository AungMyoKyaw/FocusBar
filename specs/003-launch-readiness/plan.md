# Implementation Plan: Launch Readiness

**Branch**: `003-launch-readiness` | **Date**: 2026-02-14 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-launch-readiness/spec.md`

## Summary

Harden FocusBar for production release by adding a first-launch onboarding flow, comprehensive error handling and logging, full accessibility (VoiceOver) support, Dark/Light mode verification, and operational polish (About screen, feedback link, version display). This builds on the existing codebase which currently has zero onboarding, zero accessibility, and silent error swallowing throughout all services.

## Technical Context

**Language/Version**: Swift 5.9+  
**Primary Dependencies**: SwiftUI, SwiftData, EventKit, UserNotifications, OSLog  
**Storage**: SwiftData (sessions, achievements, daily stats) + UserDefaults (preferences, onboarding flag, XP, level, streak)  
**Testing**: Swift Testing framework (`@Test`, `#expect`) for unit tests, XCTest for UI tests  
**Target Platform**: macOS 13.0+ (Ventura)  
**Project Type**: Single native macOS application (menu bar only)  
**Performance Goals**: No regression from baseline — <500ms launch, <50MB idle memory  
**Constraints**: App Sandbox, no network access, optional EventKit + UserNotifications permissions  
**Scale/Scope**: ~8 new/modified views, 1 new service (logging), modifications to all 5 existing services for error propagation

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The project constitution is a blank template with no project-specific gates defined. No violations exist. Proceeding to Phase 0.

**Post-Phase 1 re-check**: No constitution violations. The design is purely additive — one new service (LoggingService), one new ViewModel, four new onboarding views, one error banner component. All modifications to existing services are non-breaking (adding logging and error propagation). No architectural changes, no new dependencies beyond OSLog (Apple framework). Complexity remains minimal.

## Project Structure

### Documentation (this feature)

```text
specs/003-launch-readiness/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (service contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
FocusBar/
├── App/
│   └── FocusBarApp.swift              # Modified: add onboarding window scene, inject LoggingService
├── Models/
│   └── (no new models — onboarding flag uses @AppStorage)
├── ViewModels/
│   ├── OnboardingViewModel.swift      # NEW: onboarding flow state, permission requests
│   ├── TimerViewModel.swift           # Modified: error propagation to UI
│   ├── RemindersViewModel.swift       # Modified: graceful permission denial handling
│   └── SettingsViewModel.swift        # Modified: add feedback/about data
├── Views/
│   ├── Onboarding/
│   │   ├── OnboardingContainerView.swift  # NEW: multi-step onboarding flow
│   │   ├── WelcomeStepView.swift          # NEW: step 1 — value proposition
│   │   ├── PermissionsStepView.swift      # NEW: step 2 — permission primer + requests
│   │   └── ReadyStepView.swift            # NEW: step 3 — "Get Started" confirmation
│   ├── MenuBar/
│   │   └── MenuBarView.swift              # Modified: accessibility labels on all controls
│   ├── Settings/
│   │   └── SettingsView.swift             # Modified: add About tab, Feedback link
│   ├── Stats/
│   │   ├── StatsView.swift                # Modified: accessibility labels
│   │   └── ChartViews.swift               # Modified: accessibility labels
│   ├── Achievements/
│   │   └── AchievementsView.swift         # Modified: accessibility labels
│   └── Components/
│       ├── ReminderPicker.swift           # Modified: accessibility labels
│       ├── XPProgressView.swift           # Modified: accessibility labels
│       └── ErrorBannerView.swift          # NEW: reusable error banner component
├── Services/
│   ├── LoggingService.swift               # NEW: OSLog-based structured logging
│   ├── TimerService.swift                 # Modified: error logging, guard against rapid toggling
│   ├── GamificationService.swift          # Modified: error logging
│   ├── NotificationService.swift          # Modified: error logging, return Result types
│   ├── ReminderService.swift              # Modified: error logging, fix deprecation, Result types
│   ├── ExportService.swift                # Modified: error logging, user-facing export errors
│   └── StreakService.swift                # Modified: error logging
├── Utilities/
│   ├── Constants.swift                    # Modified: add app metadata constants
│   └── UserDefaultsKeys.swift             # Modified: add hasCompletedOnboarding key
└── Resources/
    └── Assets.xcassets/                   # Modified: verify color assets for Dark/Light

FocusBarTests/
├── OnboardingViewModelTests.swift         # NEW
├── LoggingServiceTests.swift              # NEW
└── ErrorHandlingTests.swift               # NEW
```

**Structure Decision**: Extends existing single-app structure. New `Onboarding/` view group follows the feature-area pattern. `LoggingService` follows existing service pattern. No architectural changes — purely additive.

## Complexity Tracking

No constitution violations to justify.
