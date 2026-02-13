# Research: FocusBar — macOS Menu Bar Pomodoro Timer

**Branch**: `001-focusbar-pomodoro-app` | **Date**: 2026-02-14

## R1: Menu Bar Architecture (MenuBarExtra)

**Decision**: Use SwiftUI `MenuBarExtra` with `.menuBarExtraStyle(.window)` for the primary UI.

**Rationale**: 
- `MenuBarExtra` is available from macOS 13.0+ and is the native SwiftUI way to create menu bar apps.
- The `.window` style allows rich SwiftUI content (buttons, progress bars, lists) — not just simple menu items.
- Setting the app to menu-bar-only (no `WindowGroup`, set `LSUIElement = true` in Info.plist) hides the Dock icon.
- The label parameter accepts a custom `View`, enabling dynamic countdown text ("🍅 18:32") or progress indicators in the menu bar itself.

**Alternatives considered**:
- `NSStatusItem` + `NSPopover` (AppKit): More control but loses SwiftUI declarative benefits. Only needed for pre-macOS 13.
- `WindowGroup` + menu bar extra hybrid: Unnecessary complexity; the app should be menu-bar-only.

## R2: Timer Accuracy and Sleep/Wake Handling

**Decision**: Use `ContinuousClock` / `Date`-based elapsed time instead of `Timer.scheduledTimer` tick counting.

**Rationale**:
- `Timer.scheduledTimer` drifts over time and pauses during system sleep.
- Store the session start `Date` and compute remaining time as `duration - Date().timeIntervalSince(startDate)` on each tick.
- Use `DispatchSource.makeTimerSource` or a 1-second `Timer` purely for UI refresh — not for timekeeping.
- On wake from sleep, the next tick automatically picks up the correct elapsed time.
- `ProcessInfo.processInfo.systemUptime` (monotonic) can supplement for detecting sleep gaps.
- Subscribe to `NSWorkspace.willSleepNotification` / `didWakeNotification` for explicit sleep/wake handling (auto-pause option).

**Alternatives considered**:
- Pure `Timer` tick counting: Drifts, misses ticks during sleep. Rejected.
- `DispatchSourceTimer` with wall clock: Works but `Date`-based approach is simpler and equally accurate.

## R3: Persistence Strategy (SwiftData vs Core Data)

**Decision**: Use SwiftData (`@Model` macro) for all structured data (sessions, achievements, daily stats). Use `@AppStorage` / `UserDefaults` for scalar preferences.

**Rationale**:
- The project already uses SwiftData (established in Xcode project template).
- SwiftData provides `@Query` for reactive UI updates — ideal for stats views.
- SwiftData automatically handles schema migration for simple changes via lightweight migration.
- `@AppStorage` is the idiomatic SwiftUI way to persist preferences with two-way binding.
- No need for Core Data's complexity; SwiftData covers all use cases here.

**Alternatives considered**:
- Core Data: More verbose, requires `.xcdatamodeld` file. SwiftData supersedes it for new projects.
- SQLite directly: Too low-level; loses SwiftUI integration.
- JSON files: Poor query capability for statistics aggregation.

## R4: EventKit Integration Pattern

**Decision**: Create a `ReminderService` class that wraps `EKEventStore`, requests authorization lazily (on first use), and exposes async methods.

**Rationale**:
- EventKit requires explicit `requestFullAccessToReminders()` (iOS 17+ / macOS 14+ API).
- Authorization should be requested only when the user first interacts with the task-linking feature, not at launch.
- All EventKit operations should be on a background thread with results dispatched to main.
- The service must handle authorization denial gracefully (return empty results, show permission prompt).
- Entitlement `com.apple.security.personal-information.reminders` required in `.entitlements` file.

**Alternatives considered**:
- Direct EKEventStore usage in ViewModels: Mixes concerns, harder to test. Rejected.
- Third-party Reminders wrappers: None mature enough; EventKit API is straightforward.

## R5: Notification System

**Decision**: Use `UNUserNotificationCenter` with local notifications. Request authorization lazily. Support sound, banner, and optional alert categories.

**Rationale**:
- `UNUserNotificationCenter` is the standard macOS notification API.
- Silent mode by default means no permission prompt until user enables sounds.
- Notification categories can include actions ("Start Break", "Skip Break") for richer UX.
- Custom sounds must be under 30 seconds and bundled in the app.

**Alternatives considered**:
- `NSUserNotification` (deprecated): Removed in macOS 12+. Rejected.
- System sounds via `NSSound`: Only for audio; doesn't show banners.

## R6: Gamification Engine Design

**Decision**: Implement `GamificationService` as a pure-logic class that computes XP, evaluates achievements, and manages levels — testable without UI.

**Rationale**:
- XP formula: `baseXP × streakMultiplier × levelMultiplier + dailyGoalBonus`
- Streak multiplier: `min(1 + (streakDays × 0.05), 2.0)`
- Level multiplier: `1 + (currentLevel × 0.05)`
- Achievement evaluation runs after every session completion, checking all unlockable conditions.
- All 20+ achievements defined as data (enum or static array), not hardcoded logic branches.
- Achievement definitions include: id, title, description, category, condition closure, XP bonus.

**Alternatives considered**:
- Inline XP logic in ViewModel: Untestable, duplicated. Rejected.
- External achievement config file: Over-engineering for a fixed set of 20 achievements.

## R7: Statistics and Charts

**Decision**: Use Swift Charts framework (macOS 13+) for all visualizations. Query SwiftData with `@Query` and `#Predicate` for filtered aggregations.

**Rationale**:
- Swift Charts is native, performant, and integrates seamlessly with SwiftUI.
- `@Query` with predicates allows date-range filtering (daily/weekly/monthly) directly in views.
- `DailyStats` pre-aggregated model avoids expensive session-by-session queries for dashboard.
- For time-of-day charts, aggregate from `Session.startTime` hour component.

**Alternatives considered**:
- Custom Canvas drawing: Much more work, less accessible. Rejected.
- Third-party charting libs (e.g., Charts by danielgindi): Unnecessary with native Swift Charts.

## R8: Data Export Format

**Decision**: Export to a single JSON file using `Codable` conformance on SwiftData models. Use `NSSavePanel` for file location selection.

**Rationale**:
- JSON is human-readable, widely supported, and trivial to implement with `Codable`.
- `NSSavePanel` is the standard macOS file-save dialog, sandbox-compatible.
- Export includes: sessions array, achievements array, daily stats array, preferences dictionary.
- File naming: `focusbar-export-YYYY-MM-DD.json`.

**Alternatives considered**:
- CSV: Multiple files needed for different entity types. More complex.
- SQLite dump: Not human-readable, tool-dependent.

## R9: App Lifecycle (Menu-Bar-Only)

**Decision**: Set `LSUIElement = true` in Info.plist to hide Dock icon. Use only `MenuBarExtra` scene (no `WindowGroup`). Open settings/stats as separate windows via `openWindow(id:)`.

**Rationale**:
- `LSUIElement` (Application is agent) hides the app from Dock and app switcher.
- Settings and Stats views need their own windows, opened via `@Environment(\.openWindow)`.
- Multiple `Window` scenes can coexist with `MenuBarExtra` in the same `App` struct.

**Alternatives considered**:
- Popover-only (no separate windows): Too cramped for stats/settings. Rejected.
- `NSApplication.setActivationPolicy(.accessory)`: Same effect as `LSUIElement` but less declarative.
