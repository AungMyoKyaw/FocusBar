# Data Model: Launch Readiness

**Branch**: `003-launch-readiness` | **Date**: 2026-02-14

## Overview

This feature is primarily a UX/stability hardening effort. It introduces **no new SwiftData models**. All new persistent state uses `@AppStorage` (UserDefaults) since the data is scalar preferences, not structured records.

## New Data Entities

### OnboardingState (UserDefaults via @AppStorage)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `hasCompletedOnboarding` | `Bool` | `false` | Set to `true` when user completes the onboarding flow. Controls whether onboarding window opens on launch. |

**Storage location**: `UserDefaultsKeys.hasCompletedOnboarding`  
**Access pattern**: Read on app launch to decide window scene. Written once at end of onboarding.

---

### AppError (In-Memory Enum — Not Persisted)

Transient error state passed from Services → ViewModels → Views for display.

```
AppError
├── dataError(String)          — SwiftData save/fetch failure
├── permissionDenied(type)     — Notifications or Reminders denied
│   └── PermissionType: notifications | reminders
├── exportFailed(String)       — JSON export failure
└── unknown(String)            — Catch-all for unexpected errors
```

**Properties**:
- `localizedDescription: String` — User-friendly message for display in ErrorBannerView
- `debugDescription: String` — Detailed message for OSLog logging

**Lifecycle**: Set on ViewModel when error occurs → displayed by View → auto-cleared after 5 seconds or on user dismiss.

---

### LogCategory (Static Enum — Not Persisted)

Categories for structured OSLog logging.

| Category | Subsystem | Usage |
|----------|-----------|-------|
| `timer` | `com.aungmyokyaw.FocusBar` | Timer state transitions, sleep/wake |
| `gamification` | `com.aungmyokyaw.FocusBar` | XP awards, level ups, achievements |
| `reminders` | `com.aungmyokyaw.FocusBar` | EventKit operations, permission changes |
| `data` | `com.aungmyokyaw.FocusBar` | SwiftData save/fetch, export |
| `ui` | `com.aungmyokyaw.FocusBar` | Onboarding flow, navigation events |
| `permissions` | `com.aungmyokyaw.FocusBar` | Permission requests and status changes |

## Existing Models — No Changes

The following SwiftData models from `001-focusbar-pomodoro-app` are **unchanged**:

- **Session** (`@Model`): Focus/break session records
- **DailyStats** (`@Model`): Daily aggregate statistics
- **Achievement** (`@Model`): Unlocked achievement records

## State Transitions

### Onboarding Flow State Machine

```
[launch] → check hasCompletedOnboarding
  ├── false → open Onboarding Window
  │   ├── Step 1: Welcome (value proposition)
  │   ├── Step 2: Permissions (primer + system request)
  │   │   ├── Notifications: request → granted/denied (continue either way)
  │   │   └── Reminders: request → granted/denied/skipped (continue either way)
  │   └── Step 3: Ready → "Get Started" → set hasCompletedOnboarding=true → close window
  └── true → normal launch (MenuBarExtra only)
```

### Error Display State Machine

```
[error occurs in Service]
  → Service throws AppError
  → ViewModel catches, logs via LoggingService, sets currentError
  → View shows ErrorBannerView
  → [after 5s OR user taps dismiss] → currentError = nil → banner hides
```
