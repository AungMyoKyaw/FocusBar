# Tasks: Launch Readiness (Onboarding, Error Handling & Accessibility)

**Input**: Design documents from `/specs/003-launch-readiness/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/services.md

**Tests**: Not included — not explicitly requested in feature specification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **macOS app**: `FocusBar/` source directory at repository root
- Existing project — no project initialization needed

---

## Phase 1: Setup & Foundational Infrastructure

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented. Since this is an existing project, setup and foundational tasks are merged.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T001 [P] Create `LoggingService` with OSLog `Logger` instances for 6 categories (timer, gamification, reminders, notifications, export, general) in `FocusBar/Services/LoggingService.swift`
- [X] T002 [P] Create `AppError` enum with cases `.timerError`, `.reminderError`, `.notificationError`, `.exportError` conforming to `LocalizedError` in `FocusBar/Models/AppError.swift`
- [X] T003 [P] Add `hasCompletedOnboarding` key to `UserDefaultsKeys` in `FocusBar/Utilities/UserDefaultsKeys.swift`
- [X] T004 [P] Add `feedbackURL`, `appVersion`, and `appBuildNumber` constants to `FocusBar/Utilities/Constants.swift`

**Checkpoint**: Foundation ready — logging, error types, and configuration keys available for all user stories.

---

## Phase 2: User Story 1 — Onboarding (Priority: P1) 🎯 MVP

**Goal**: First-launch users see a 3-step onboarding window (Welcome → Permissions → Ready) that introduces the app, requests notification/reminder permissions, and marks onboarding complete.

**Independent Test**: Reset onboarding via `defaults delete aungmyokyaw.com.FocusBar hasCompletedOnboarding`, relaunch app, verify 3-step flow appears and permissions are requested. Completing onboarding should prevent it from showing on next launch.

### Implementation for User Story 1

- [X] T005 [US1] Create `OnboardingViewModel` with step navigation, permission request actions, and completion logic using `@Observable` in `FocusBar/ViewModels/OnboardingViewModel.swift`
- [X] T006 [P] [US1] Create `WelcomeStepView` (step 1: app intro, feature highlights, Continue button) in `FocusBar/Views/Onboarding/WelcomeStepView.swift`
- [X] T007 [P] [US1] Create `PermissionsStepView` (step 2: notification + reminder permission buttons with live status indicators) in `FocusBar/Views/Onboarding/PermissionsStepView.swift`
- [X] T008 [P] [US1] Create `ReadyStepView` (step 3: summary of choices, Get Started button) in `FocusBar/Views/Onboarding/ReadyStepView.swift`
- [X] T009 [US1] Create `OnboardingContainerView` with step indicator and navigation wrapping the 3 step views in `FocusBar/Views/Onboarding/OnboardingContainerView.swift`
- [X] T010 [US1] Add onboarding `Window` scene to `FocusBarApp` that shows on first launch when `hasCompletedOnboarding` is false, and wire `OnboardingViewModel` in `FocusBar/App/FocusBarApp.swift`

**Checkpoint**: Onboarding flow fully functional — first-launch users guided through setup. Independently testable.

---

## Phase 3: User Story 2 — Error Handling & Logging (Priority: P1)

**Goal**: All services log operations via OSLog, throw typed `AppError` instead of swallowing errors silently, and ViewModels display errors to users via a dismissable/auto-dismiss banner.

**Independent Test**: Revoke Reminders permission in System Settings, attempt to link a reminder in the app — verify error banner appears (not silent failure). Check Console.app for OSLog output with category filters.

### Implementation for User Story 2

- [X] T011 [US2] Create `ErrorBannerView` component with auto-dismiss (5s), manual dismiss, error icon, and message display in `FocusBar/Views/Components/ErrorBannerView.swift`
- [X] T012 [US2] Add OSLog logging and throw `AppError` instead of silent `try?` in `TimerService`, add 300ms debounce guard on start/pause/reset actions in `FocusBar/Services/TimerService.swift`
- [X] T013 [P] [US2] Add OSLog logging and throw `AppError.reminderError` instead of returning nil/false, fix `EKAuthorizationStatus.authorized` deprecation with `#available(macOS 14, *)` branching in `FocusBar/Services/ReminderService.swift`
- [X] T014 [P] [US2] Add OSLog logging to all notification scheduling and permission requests in `FocusBar/Services/NotificationService.swift`
- [X] T015 [P] [US2] Add OSLog logging and throw `AppError.exportError` instead of silent failures in `FocusBar/Services/ExportService.swift`
- [X] T016 [P] [US2] Add OSLog logging to XP calculation, level-up, and achievement evaluation in `FocusBar/Services/GamificationService.swift`
- [X] T017 [P] [US2] Add OSLog logging to streak calculation, freeze logic, and daily reset in `FocusBar/Services/StreakService.swift`
- [X] T018 [US2] Update `TimerViewModel` to catch `AppError` from services and expose error state for `ErrorBannerView` display in `FocusBar/ViewModels/TimerViewModel.swift`
- [X] T019 [US2] Update `RemindersViewModel` to handle `AppError.reminderError`, show graceful permission-denied message, and expose error state in `FocusBar/ViewModels/RemindersViewModel.swift`
- [X] T020 [US2] Integrate `ErrorBannerView` into `MenuBarView` bound to ViewModel error states in `FocusBar/Views/MenuBar/MenuBarView.swift`
- [X] T021 [US2] Replace `fatalError()` on `ModelContainer` creation failure with graceful fallback (in-memory store + error logging) in `FocusBar/App/FocusBarApp.swift`

**Checkpoint**: All services log via OSLog, errors propagate to UI via banners, no silent failures. Independently testable.

---

## Phase 4: User Story 3 — UI/UX & Accessibility (Priority: P2)

**Goal**: All interactive elements have VoiceOver accessibility labels/hints, the app respects Dark/Light mode, and Settings includes an About tab with version info and feedback link.

**Independent Test**: Enable VoiceOver (Cmd+F5), navigate the entire app — every control should be announced meaningfully. Toggle Dark/Light mode in System Settings — all views should remain legible with proper contrast.

### Implementation for User Story 3

- [X] T022 [P] [US3] Add `.accessibilityLabel`, `.accessibilityHint`, and `.accessibilityValue` to all controls (timer, start/pause/reset buttons, session type, navigation) in `FocusBar/Views/MenuBar/MenuBarView.swift`
- [X] T023 [P] [US3] Add `.accessibilityLabel` and `.accessibilityHint` to timer countdown display and menu bar icon states in `FocusBar/Views/MenuBar/TimerDisplayView.swift`
- [X] T024 [P] [US3] Add About tab with app version, build number, credits, and feedback URL link to `SettingsView`, plus accessibility labels on all tab controls in `FocusBar/Views/Settings/SettingsView.swift`
- [X] T025 [P] [US3] Add `.accessibilityLabel` and `.accessibilityValue` to all stat cards, summary values, and date range controls in `FocusBar/Views/Stats/StatsView.swift`
- [X] T026 [P] [US3] Add `.accessibilityLabel` with data descriptions to all chart elements (bars, axes, legends) in `FocusBar/Views/Stats/ChartViews.swift`
- [X] T027 [P] [US3] Add `.accessibilityLabel` and `.accessibilityHint` to achievement cards (name, description, locked/unlocked state) in `FocusBar/Views/Achievements/AchievementsView.swift`
- [X] T028 [P] [US3] Add `.accessibilityLabel` to reminder search field, dropdown items, and quick-add button in `FocusBar/Views/Components/ReminderPicker.swift`
- [X] T029 [P] [US3] Add `.accessibilityLabel` and `.accessibilityValue` to XP bar, level badge, and streak counter in `FocusBar/Views/Components/XPProgressView.swift`
- [X] T030 [US3] Audit all views for Dark/Light mode color contrast — replace any hardcoded colors with semantic system colors (`Color.primary`, `Color.secondary`, `.background`) across all view files

**Checkpoint**: Full VoiceOver navigation works, About tab visible, Dark/Light mode renders correctly. Independently testable.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and documentation updates.

- [X] T031 [P] Add accessibility labels to onboarding views (WelcomeStepView, PermissionsStepView, ReadyStepView) in `FocusBar/Views/Onboarding/`
- [X] T032 Run quickstart.md validation — verify all build/run/test commands work correctly per `specs/003-launch-readiness/quickstart.md`
- [X] T033 Update `AGENTS.md` to document new files (LoggingService, AppError, Onboarding views, ErrorBannerView) and modified service contracts

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup & Foundational)**: No dependencies — can start immediately
- **Phase 2 (US1 Onboarding)**: Depends on T003 (`hasCompletedOnboarding` key) from Phase 1
- **Phase 3 (US2 Error Handling)**: Depends on T001 (`LoggingService`) and T002 (`AppError`) from Phase 1
- **Phase 4 (US3 Accessibility)**: No Phase 1 dependencies — can start after Phase 1 if desired, but recommended after Phase 3 since error views need accessibility too
- **Phase 5 (Polish)**: Depends on all user story phases being complete

### User Story Dependencies

- **User Story 1 (P1 - Onboarding)**: Depends only on Phase 1 (T003). Independent of US2 and US3.
- **User Story 2 (P1 - Error Handling)**: Depends only on Phase 1 (T001, T002). Independent of US1 and US3.
- **User Story 3 (P2 - Accessibility)**: No Phase 1 dependency. Can run in parallel with US1/US2, but best after US2 so error banner gets accessibility too (T020 creates the view, T022+ adds accessibility).

### Within Each User Story

- Models/enums before services
- Services before ViewModels
- ViewModels before Views
- Component views before container/integration views
- Story complete before moving to next priority

### Parallel Opportunities

- **Phase 1**: All 4 tasks (T001–T004) can run in parallel — different files, no dependencies
- **Phase 2 (US1)**: T006, T007, T008 can run in parallel (3 independent step views), then T009 integrates them
- **Phase 3 (US2)**: T013–T017 can run in parallel (5 independent service modifications), then T018–T021 wire ViewModels and Views
- **Phase 4 (US3)**: T022–T029 can ALL run in parallel (8 independent view files), then T030 is a cross-cutting audit
- **Cross-story**: US1 and US2 can run in parallel after Phase 1 completion

---

## Parallel Example: Phase 1

```text
# All foundational tasks in parallel (different files):
T001: Create LoggingService in FocusBar/Services/LoggingService.swift
T002: Create AppError enum in FocusBar/Models/AppError.swift
T003: Add hasCompletedOnboarding to FocusBar/Utilities/UserDefaultsKeys.swift
T004: Add constants to FocusBar/Utilities/Constants.swift
```

## Parallel Example: User Story 2 (Service Modifications)

```text
# All service logging tasks in parallel (different files):
T013: ReminderService — logging + deprecation fix
T014: NotificationService — logging
T015: ExportService — logging + error throwing
T016: GamificationService — logging
T017: StreakService — logging
```

## Parallel Example: User Story 3 (Accessibility)

```text
# All accessibility tasks in parallel (different view files):
T022: MenuBarView accessibility
T023: TimerDisplayView accessibility
T024: SettingsView About tab + accessibility
T025: StatsView accessibility
T026: ChartViews accessibility
T027: AchievementsView accessibility
T028: ReminderPicker accessibility
T029: XPProgressView accessibility
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup & Foundational (T001–T004)
2. Complete Phase 2: User Story 1 — Onboarding (T005–T010)
3. **STOP and VALIDATE**: Test onboarding flow independently
4. Build and demo if ready

### Incremental Delivery

1. Complete Phase 1 → Foundation ready
2. Add User Story 1 (Onboarding) → Test independently → Demo (MVP!)
3. Add User Story 2 (Error Handling) → Test independently → Demo
4. Add User Story 3 (Accessibility) → Test independently → Demo
5. Complete Polish → Final validation
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Phase 1 together (4 parallel tasks)
2. Once Phase 1 is done:
   - Developer A: User Story 1 (Onboarding)
   - Developer B: User Story 2 (Error Handling)
3. After US1 and US2 complete:
   - Developer A or B: User Story 3 (Accessibility) — benefits from having all views finalized
4. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Tests not included — add test tasks if TDD is desired later
