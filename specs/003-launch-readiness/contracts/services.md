# Service Contracts: Launch Readiness

**Branch**: `003-launch-readiness` | **Date**: 2026-02-14

## Overview

This feature adds one new service (`LoggingService`) and modifies all existing services to propagate errors instead of swallowing them. No REST/GraphQL APIs — this is a native macOS app with internal service contracts only.

---

## New Service: LoggingService

**Purpose**: Centralized structured logging via OSLog. Provides category-specific loggers for consistent log formatting across the app.

### Interface

```
LoggingService (static/singleton)
├── logger(for: LogCategory) → Logger
│   Input: LogCategory enum value
│   Output: Configured Logger instance for that category
│   Behavior: Returns a Logger with subsystem "com.aungmyokyaw.FocusBar" and the category string
│
├── logError(_ error: AppError, context: String?)
│   Input: AppError instance, optional context string
│   Output: None (side effect: writes to OSLog at .error level)
│   Behavior: Formats error with context and writes to appropriate category logger
│
├── logInfo(_ message: String, category: LogCategory)
│   Input: Message string, category
│   Output: None (side effect: writes to OSLog at .info level)
│
└── logDebug(_ message: String, category: LogCategory)
    Input: Message string, category
    Output: None (side effect: writes to OSLog at .debug level)
```

### LogCategory Values
`timer`, `gamification`, `reminders`, `data`, `ui`, `permissions`

---

## New ViewModel: OnboardingViewModel

**Purpose**: Manages the multi-step onboarding flow state and permission request logic.

### Interface

```
OnboardingViewModel (@Observable)
├── Properties
│   ├── currentStep: OnboardingStep (welcome | permissions | ready)
│   ├── notificationStatus: PermissionStatus (unknown | granted | denied)
│   ├── reminderStatus: PermissionStatus (unknown | granted | denied | skipped)
│   └── isComplete: Bool (computed: currentStep == .ready AND user tapped Get Started)
│
├── advanceToNext()
│   Behavior: Moves from current step to next step in sequence
│   Pre: currentStep != .ready
│   Post: currentStep advanced by one
│
├── requestNotificationPermission() async
│   Behavior: Triggers UNUserNotificationCenter.requestAuthorization
│   Post: notificationStatus updated to granted or denied
│   Errors: Logs via LoggingService, sets status to denied on failure
│
├── requestReminderPermission() async
│   Behavior: Triggers EKEventStore permission request (version-aware)
│   Post: reminderStatus updated to granted or denied
│   Errors: Logs via LoggingService, sets status to denied on failure
│
├── skipReminders()
│   Behavior: Sets reminderStatus to skipped, advances flow
│
└── completeOnboarding()
    Behavior: Sets hasCompletedOnboarding = true in UserDefaults
    Post: Onboarding window should close, app enters normal state
```

---

## Modified Service: TimerService

### Changes

```
TimerService (existing, modified)
├── NEW: lastStateChangeDate: Date (private)
│   Purpose: Debounce guard for rapid input
│
├── MODIFIED: start(type:duration:)
│   Change: Guard against rapid toggling (300ms debounce)
│   Change: Log state transition via LoggingService
│
├── MODIFIED: pause()
│   Change: Guard against rapid toggling
│   Change: Log state transition
│
├── MODIFIED: reset()
│   Change: Log state transition
│
└── MODIFIED: skip()
    Change: Log state transition
```

---

## Modified Service: NotificationService

### Changes

```
NotificationService (existing, modified)
├── MODIFIED: requestPermission() async → Bool
│   Change: Log result via LoggingService (granted/denied)
│
├── MODIFIED: sendSessionComplete(type:)
│   Change: Log errors instead of fire-and-forget
│
├── MODIFIED: sendAchievementUnlocked(name:)
│   Change: Log errors
│
├── MODIFIED: sendLevelUp(level:)
│   Change: Log errors
│
└── MODIFIED: sendDailyGoalMet()
    Change: Log errors
```

---

## Modified Service: ReminderService

### Changes

```
ReminderService (existing, modified)
├── MODIFIED: requestAccess() async → Bool
│   Change: Use #available(macOS 14, *) branching for new API
│   Change: Log result via LoggingService
│
├── MODIFIED: checkAuthorizationStatus() → EKAuthorizationStatus
│   Change: Use #available(macOS 14, *) for .fullAccess check
│
├── MODIFIED: createReminder(title:) → throws ReminderItem
│   Change: Throw AppError.permissionDenied instead of returning nil
│   Change: Log via LoggingService
│
├── MODIFIED: appendFocusTime(to:minutes:) → throws
│   Change: Throw instead of returning false
│   Change: Log via LoggingService
│
└── MODIFIED: markComplete(id:) → throws
    Change: Throw instead of returning false
    Change: Log via LoggingService
```

---

## Modified Service: ExportService

### Changes

```
ExportService (existing, modified)
├── MODIFIED: exportToJSON(sessions:stats:achievements:) → throws URL
│   Change: Throw AppError.exportFailed instead of silent try?
│   Change: Log via LoggingService
│   Change: Surface error to user via ViewModel → ErrorBannerView
```

---

## Modified Service: GamificationService

### Changes

```
GamificationService (existing, modified)
├── MODIFIED: awardXP(for:) 
│   Change: Log XP awards and level-ups via LoggingService at .info level
│
├── MODIFIED: evaluateAchievements(context:) 
│   Change: Log newly unlocked achievements via LoggingService at .info level
```

---

## Modified Service: StreakService

### Changes

```
StreakService (existing, modified)
├── MODIFIED: updateStreak(for:)
│   Change: Log streak continuations, breaks, and freezes via LoggingService
│
├── MODIFIED: applyFreeze()
│   Change: Log freeze application via LoggingService
```

---

## New UI Component: ErrorBannerView

**Purpose**: Reusable error display component shown at the top of views when an error occurs.

### Interface

```
ErrorBannerView (SwiftUI View)
├── Input
│   ├── error: AppError (the error to display)
│   └── onDismiss: () -> Void (callback when dismissed)
│
├── Behavior
│   ├── Shows error.localizedDescription in a colored banner
│   ├── Includes dismiss button (X)
│   ├── Auto-dismisses after 5 seconds
│   └── Slides in from top with animation
│
├── Appearance
│   ├── Warning color background (system yellow/orange)
│   ├── Adapts to Dark/Light mode via semantic colors
│   └── Accessible: VoiceOver announces error message
```

---

## AppError Enum

```
AppError (enum, Identifiable, LocalizedError)
├── dataError(String)
│   localizedDescription: "Couldn't save your progress. Please try again."
│   debugDescription: [includes original error message]
│
├── permissionDenied(PermissionType)
│   PermissionType: .notifications | .reminders
│   localizedDescription: "FocusBar needs [permission] access. Enable it in System Settings."
│   debugDescription: [includes permission type and status]
│
├── exportFailed(String)
│   localizedDescription: "Export failed. Please try saving to a different location."
│   debugDescription: [includes file path and error]
│
└── unknown(String)
    localizedDescription: "Something went wrong. Please try again."
    debugDescription: [includes original error message]
```
