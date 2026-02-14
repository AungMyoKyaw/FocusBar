# Research: Launch Readiness

**Branch**: `003-launch-readiness` | **Date**: 2026-02-14

## Research Items

### R1: macOS Onboarding Patterns for Menu Bar Apps

**Decision**: Use a standalone `Window` scene for onboarding (not a sheet over MenuBarExtra). The onboarding window appears on first launch, and the MenuBarExtra is present but non-functional until onboarding completes.

**Rationale**: `MenuBarExtra` with `.window` style has limited screen real estate (~280px wide). An onboarding flow needs space for illustrations, explanations, and permission primers. A dedicated `Window` scene (like Settings/Stats already use) provides a full-size canvas. SwiftUI's `Window(id:)` can be opened programmatically via `OpenWindowAction`.

**Alternatives considered**:
- **Sheet on MenuBarExtra**: Too cramped; MenuBarExtra windows don't support standard sheet presentations reliably.
- **Alert-based flow**: Too spartan for a polished first impression. No room for branding or illustrations.
- **No onboarding, just start**: Fails App Store guidelines for apps requiring permissions — Apple expects context before requesting.

---

### R2: Permission Request "Primer" Pattern on macOS

**Decision**: Show a custom "primer" screen explaining *why* the app needs each permission *before* triggering the system permission dialog. This is the standard pre-permission pattern.

**Rationale**: Apple's Human Interface Guidelines recommend explaining the value of a permission before requesting it. Once a user denies a system prompt, re-requesting requires them to navigate to System Settings manually. A primer screen reduces denial rates significantly.

**Implementation approach**:
1. **Notifications**: Show primer explaining session-complete alerts → call `UNUserNotificationCenter.requestAuthorization()`.
2. **Reminders**: Show primer explaining task-linking benefit → call `EKEventStore.requestFullAccessToReminders()` (macOS 14+) or `requestAccess(to: .reminder)` (macOS 13).
3. **Reminders is optional**: If user skips or denies, all non-reminder features remain fully functional. Show "Enable later in Settings" option.

**Alternatives considered**:
- **Request at first use only**: Misses the opportunity to educate upfront; confusing if the system dialog appears mid-workflow.
- **Request both at launch without primer**: Higher denial rate; poor UX.

---

### R3: Structured Logging on macOS with OSLog

**Decision**: Use Apple's `OSLog` framework (via `Logger`) for structured logging. No third-party dependencies.

**Rationale**: `OSLog`/`Logger` is the standard macOS logging framework. It integrates with Console.app, has subsystem/category filtering, supports log levels (debug/info/notice/error/fault), is performant (deferred string interpolation), and requires zero dependencies. For a sandboxed menu bar app, it's the right choice.

**Implementation approach**:
- Create a `LoggingService` with static `Logger` instances per subsystem category (Timer, Gamification, Reminders, Data, UI).
- Replace all silent `catch {}` blocks with `Logger.error()` calls.
- Use `.fault` level for conditions that should never happen (data corruption).
- Use `.error` for recoverable but unexpected failures (save failed, permission denied).
- Use `.info` for lifecycle events (session started, achievement unlocked).

**Alternatives considered**:
- **SwiftLog**: Overkill for a single-app, no-network, no-backend scenario. Adds a dependency.
- **print() statements**: Not structured, not filterable, not available in release builds via Console.app.
- **Custom file logging**: Unnecessary complexity; OSLog already persists to the unified log.

---

### R4: Error Propagation Pattern in SwiftUI + @Observable

**Decision**: Use a centralized error state on ViewModels that views observe. Errors bubble up from Services → ViewModels → Views via an `@Observable` `currentError` property. A reusable `ErrorBannerView` component displays errors.

**Rationale**: SwiftUI's declarative nature means errors should be part of the view state. The `@Observable` macro already handles change propagation. A shared `AppError` enum with user-facing messages keeps error handling consistent.

**Implementation approach**:
1. Define `AppError` enum with cases: `.dataError(String)`, `.permissionDenied(PermissionType)`, `.exportFailed(String)`, `.unknown(String)`.
2. Each `AppError` case provides a `localizedDescription` (user-friendly) and `debugDescription` (for logging).
3. Services throw errors instead of returning `nil`/`false` silently.
4. ViewModels catch errors, log via `LoggingService`, and set `currentError`.
5. Views display `ErrorBannerView` when `currentError != nil`, auto-dismissing after 5 seconds.

**Alternatives considered**:
- **Global error handler (NotificationCenter)**: Decoupled but harder to test; SwiftUI prefers state-driven UI.
- **Result types on every method**: Too verbose for this app's scale; cleaner to throw and catch at the ViewModel boundary.
- **Alert-based errors**: Too intrusive for non-critical errors; banners are less disruptive.

---

### R5: VoiceOver Accessibility for macOS Menu Bar Apps

**Decision**: Add `.accessibilityLabel`, `.accessibilityHint`, and `.accessibilityValue` to all interactive elements. Group related elements with `.accessibilityElement(children: .combine)` where appropriate.

**Rationale**: macOS VoiceOver reads accessibility attributes. Without them, controls are announced as generic "button" or "text". The App Store review process increasingly flags accessibility gaps. WCAG AA compliance requires all interactive elements to be programmatically determinable.

**Implementation approach**:
- **MenuBarView**: Label all buttons (Start/Pause/Resume/Skip/Reset), timer display (announce remaining time), XP bar (announce level and progress).
- **SettingsView**: All tabs, steppers, toggles, and pickers already have some implicit labels from SwiftUI, but add explicit labels for clarity.
- **StatsView/ChartViews**: Charts need `.accessibilityLabel` with summary data (e.g., "Focus hours chart, 12 hours this week").
- **AchievementsView**: Each achievement card needs label (name, description, locked/unlocked status).
- **ReminderPicker**: Search field and list items need labels.

**Alternatives considered**:
- **Accessibility audit tool only**: Passive; we need active implementation.
- **Third-party accessibility library**: Unnecessary; SwiftUI's built-in modifiers are sufficient.

---

### R6: Dark/Light Mode Support in SwiftUI

**Decision**: Audit all views for hardcoded colors and replace with semantic colors (`.primary`, `.secondary`, `.accentColor`, or named colors in asset catalog with Dark/Light variants).

**Rationale**: SwiftUI views that use system semantic colors automatically adapt to Dark/Light mode. The current codebase likely uses some hardcoded colors that won't adapt. A systematic audit is needed.

**Implementation approach**:
1. Grep for hardcoded `Color(...)` with hex/RGB values.
2. Replace with semantic colors or asset catalog named colors with Both Appearances variants.
3. Test in both modes via Xcode's environment override.
4. Verify WCAG AA contrast ratios (4.5:1 for normal text, 3:1 for large text) in both modes.

**Alternatives considered**:
- **Separate color palettes**: Unnecessary complexity; semantic colors handle this automatically.

---

### R7: Rapid Input Debouncing for Timer Controls

**Decision**: Add a debounce guard on timer state transitions. Ignore repeated start/pause/stop inputs within 300ms of the last accepted input.

**Rationale**: Rapid clicking on timer controls can cause race conditions in the state machine (idle → running → paused → running in milliseconds). The Timer fires on a 1-second interval, so sub-second state changes are meaningless and potentially corrupting.

**Implementation approach**:
- Add a `lastStateChangeDate` property to `TimerService`.
- Guard all state-changing methods: if `Date().timeIntervalSince(lastStateChangeDate) < 0.3`, return early.
- Log ignored rapid inputs at `.debug` level.

**Alternatives considered**:
- **Disable button during transition**: Harder in SwiftUI's declarative model; button state flickers.
- **DispatchQueue serial queue**: Overkill; a simple date check is sufficient for UI-driven actions.

---

### R8: App Version and About Screen

**Decision**: Read version and build number from `Bundle.main.infoDictionary` and display in a new "About" tab in Settings.

**Rationale**: Standard macOS app convention. Users and support need to identify the running version. The Info.plist already contains `CFBundleShortVersionString` and `CFBundleVersion`.

**Implementation approach**:
- Add an "About" tab to `SettingsView` with: App icon, app name, version string, build number, copyright, and a "Send Feedback" mailto link.
- Read from `Bundle.main.infoDictionary?["CFBundleShortVersionString"]` and `["CFBundleVersion"]`.

**Alternatives considered**:
- **Separate About window**: Non-standard for a menu bar app; a Settings tab is more discoverable.
- **Menu item only**: Insufficient; no room for feedback link and metadata.

---

### R9: Fixing EKAuthorizationStatus Deprecation (macOS 14+)

**Decision**: Update `ReminderService` to use `EKEventStore.requestFullAccessToReminders()` on macOS 14+ and fall back to `requestAccess(to: .reminder)` on macOS 13.

**Rationale**: `EKAuthorizationStatus.authorized` is deprecated in macOS 14.0 in favor of `.fullAccess`. The current code triggers a deprecation warning. Using `#available(macOS 14, *)` branching handles both.

**Implementation approach**:
- Use `if #available(macOS 14, *)` to branch authorization checks.
- On macOS 14+: check for `.fullAccess`, request via `requestFullAccessToReminders()`.
- On macOS 13: check for `.authorized`, request via `requestAccess(to: .reminder)`.

**Alternatives considered**:
- **Drop macOS 13 support**: Premature; macOS 13 users still exist.
- **Suppress the warning**: Hides a real API change; could break on future macOS versions.
