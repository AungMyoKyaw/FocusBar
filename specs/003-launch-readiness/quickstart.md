# Quickstart: Launch Readiness

**Branch**: `003-launch-readiness` | **Date**: 2026-02-14

## Prerequisites

- macOS 13.0+ (Ventura)
- Xcode 15.0+ with Swift 5.9+
- FocusBar base project (from `001-focusbar-pomodoro-app`) fully built and runnable

## Build & Run

```bash
# Build
xcodebuild -project FocusBar.xcodeproj -scheme FocusBar -configuration Debug build

# Run tests
xcodebuild test -project FocusBar.xcodeproj -scheme FocusBar -destination 'platform=macOS' -only-testing:FocusBarTests

# Clean
xcodebuild -project FocusBar.xcodeproj -scheme FocusBar clean
```

## Development Order

This feature should be implemented in the following order to minimize merge conflicts and ensure testability at each step:

### Phase 1: Foundation (no UI changes)
1. **LoggingService** — Create the logging infrastructure first. All subsequent changes depend on it.
2. **AppError enum** — Define the error types that services will throw.
3. **UserDefaultsKeys update** — Add `hasCompletedOnboarding` key.
4. **Constants update** — Add app metadata constants (feedback URL, etc.).

### Phase 2: Service Hardening (backend changes, no UI)
5. **TimerService** — Add debounce guard and logging.
6. **ReminderService** — Fix deprecation, add error throwing, add logging.
7. **NotificationService** — Add logging to all notification methods.
8. **ExportService** — Replace silent `try?` with thrown errors and logging.
9. **GamificationService** — Add info-level logging.
10. **StreakService** — Add logging.

### Phase 3: UI Components (new views)
11. **ErrorBannerView** — Reusable error display component.
12. **OnboardingViewModel** — Onboarding flow state management.
13. **Onboarding views** — WelcomeStepView, PermissionsStepView, ReadyStepView, OnboardingContainerView.

### Phase 4: Integration & Polish
14. **FocusBarApp.swift** — Wire onboarding window scene, inject LoggingService.
15. **SettingsView** — Add About tab with version, build number, feedback link.
16. **Accessibility pass** — Add labels/hints to all interactive elements across all views.
17. **Dark/Light mode audit** — Verify all colors are semantic, test both modes.
18. **ViewModel error propagation** — Wire AppError from services through to ErrorBannerView in key views.

### Phase 5: Testing
19. **OnboardingViewModelTests** — Test flow state transitions and permission request outcomes.
20. **LoggingServiceTests** — Test logger creation and category routing.
21. **ErrorHandlingTests** — Test error propagation from service → ViewModel.
22. **Manual testing** — VoiceOver navigation, Dark/Light mode, rapid clicking, sleep/wake.

## Testing the Onboarding Flow

To reset onboarding for testing:

```bash
# Reset the onboarding flag in UserDefaults
defaults delete aungmyokyaw.com.FocusBar hasCompletedOnboarding
```

Then relaunch the app to see the onboarding flow.

## Testing Accessibility

1. Enable VoiceOver: **System Settings → Accessibility → VoiceOver → Enable**
2. Navigate the menu bar item and verify all controls are announced
3. Use **Accessibility Inspector** (Xcode → Open Developer Tool) for automated audit

## Testing Dark/Light Mode

1. **System Settings → Appearance** → Toggle between Light and Dark
2. Verify all views adapt (MenuBar, Settings, Stats, Achievements, Onboarding)
3. Use Xcode's **Environment Overrides** (Debug bar) for quick switching during development

## Key Files to Modify

| File | Change Type | Priority |
|------|-------------|----------|
| `Services/LoggingService.swift` | NEW | P1 |
| `Utilities/AppError.swift` | NEW | P1 |
| `Views/Onboarding/*.swift` | NEW (4 files) | P1 |
| `ViewModels/OnboardingViewModel.swift` | NEW | P1 |
| `Views/Components/ErrorBannerView.swift` | NEW | P1 |
| `Services/TimerService.swift` | MODIFY | P1 |
| `Services/ReminderService.swift` | MODIFY | P1 |
| `Services/NotificationService.swift` | MODIFY | P2 |
| `Services/ExportService.swift` | MODIFY | P2 |
| `Services/GamificationService.swift` | MODIFY | P2 |
| `Services/StreakService.swift` | MODIFY | P2 |
| `App/FocusBarApp.swift` | MODIFY | P1 |
| `Views/Settings/SettingsView.swift` | MODIFY | P2 |
| `Views/MenuBar/MenuBarView.swift` | MODIFY | P2 |
| `Utilities/UserDefaultsKeys.swift` | MODIFY | P1 |
| `Utilities/Constants.swift` | MODIFY | P2 |
| All Views | MODIFY (accessibility) | P2 |
