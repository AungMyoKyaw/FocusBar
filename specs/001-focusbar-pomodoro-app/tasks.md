# Tasks: FocusBar — macOS Menu Bar Pomodoro Timer

**Input**: Design documents from `/specs/001-focusbar-pomodoro-app/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/services.md, research.md, quickstart.md

**Tests**: Not explicitly requested in the feature specification. Test tasks are omitted. Services are designed with protocols for testability when tests are added later.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Transform the Xcode template project into the FocusBar menu-bar-only app structure

- [X] T001 Remove template files: delete FocusBar/ContentView.swift and FocusBar/Item.swift
- [X] T002 Create directory structure per plan.md: FocusBar/App/, FocusBar/Models/, FocusBar/ViewModels/, FocusBar/Views/MenuBar/, FocusBar/Views/Settings/, FocusBar/Views/Stats/, FocusBar/Views/Achievements/, FocusBar/Views/Components/, FocusBar/Services/, FocusBar/Utilities/, FocusBar/Resources/Sounds/
- [X] T003 Add LSUIElement=true to Info.plist to make app menu-bar-only (no Dock icon)
- [X] T004 Add Reminders entitlement (com.apple.security.personal-information.reminders) to FocusBar.entitlements
- [X] T005 [P] Create SessionType enum (pomodoro, shortBreak, longBreak) with raw String values in FocusBar/Models/SessionType.swift
- [X] T006 [P] Create UserDefaultsKeys with type-safe @AppStorage key constants in FocusBar/Utilities/UserDefaultsKeys.swift
- [X] T007 [P] Create Constants.swift with XP level thresholds table (30 levels), achievement definitions (20 achievements), and default timer values in FocusBar/Utilities/Constants.swift

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core SwiftData models and app entry point that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T008 Create Session @Model with fields (id, startTime, endTime, duration, type, completed, reminderId, reminderTitle, xpEarned) in FocusBar/Models/Session.swift
- [X] T009 [P] Create DailyStats @Model with fields (id, date, pomodorosCompleted, totalFocusMinutes, streakMaintained, xpEarned) in FocusBar/Models/DailyStats.swift
- [X] T010 [P] Create Achievement @Model with fields (id, type, unlockedAt, metadata) in FocusBar/Models/Achievement.swift
- [X] T011 Rewrite FocusBarApp.swift as menu-bar-only app: replace WindowGroup with MenuBarExtra using .menuBarExtraStyle(.window), configure ModelContainer for Session/DailyStats/Achievement, add Window scenes for Settings and Stats in FocusBar/App/FocusBarApp.swift
- [X] T012 Create placeholder MenuBarView.swift with basic "Start Focus" button and app structure in FocusBar/Views/MenuBar/MenuBarView.swift

**Checkpoint**: App launches as menu-bar-only with tomato icon, shows dropdown with placeholder content. All SwiftData models are defined.

---

## Phase 3: User Story 1 — Start and Complete a Pomodoro Session (Priority: P1) 🎯 MVP

**Goal**: One-click Pomodoro timer with live menu bar countdown, pause/resume/reset/skip controls

**Independent Test**: Launch app → click "Start Focus" → observe 25-min countdown in menu bar → countdown completes → notification shown → session saved to SwiftData

### Implementation for User Story 1

- [X] T013 [US1] Implement TimerService with TimerServiceProtocol: Date-based elapsed time, 1-second UI refresh Timer, sleep/wake notification observers (NSWorkspace.willSleepNotification/didWakeNotification), start/pause/reset/skip methods, onSessionComplete/onTick callbacks in FocusBar/Services/TimerService.swift
- [X] T014 [US1] Implement TimerViewModel as @Observable class: expose timerState, remainingSeconds, formattedTime, currentSessionType; wire to TimerService; persist completed sessions to SwiftData ModelContext in FocusBar/ViewModels/TimerViewModel.swift
- [X] T015 [US1] Implement TimerDisplayView for menu bar label: show "🍅 MM:SS" during active session, tomato icon when idle, paused state indicator in FocusBar/Views/MenuBar/TimerDisplayView.swift
- [X] T016 [US1] Implement full MenuBarView: Start Focus button, pause/resume toggle, timer display, right-click context menu with Skip and Reset options in FocusBar/Views/MenuBar/MenuBarView.swift
- [X] T017 [US1] Update FocusBarApp.swift MenuBarExtra to use TimerDisplayView as dynamic label and MenuBarView as content in FocusBar/App/FocusBarApp.swift
- [X] T018 [US1] Implement NotificationService with UNUserNotificationCenter: requestPermission, sendSessionComplete (with session type info), playSound in FocusBar/Services/NotificationService.swift
- [X] T019 [US1] Wire NotificationService into TimerViewModel: send notification on session complete, respect soundEnabled/bannerEnabled preferences from UserDefaults in FocusBar/ViewModels/TimerViewModel.swift

**Checkpoint**: App shows live countdown in menu bar. User can start/pause/resume/reset/skip sessions. Completed sessions are persisted. Notifications fire on session end.

---

## Phase 4: User Story 2 — Automatic Session Cycling with Breaks (Priority: P1)

**Goal**: After a Pomodoro completes, automatically start short break (5 min). After every 4 Pomodoros, start long break (15 min). Cycle counter tracks position.

**Independent Test**: Complete 4 Pomodoros back-to-back → verify pattern: focus→short break→focus→short break→focus→short break→focus→long break→cycle resets

### Implementation for User Story 2

- [X] T020 [US2] Extend TimerService with session cycling logic: track completedPomodorosInCycle, auto-determine next session type (short break after Pomodoro, long break after Nth Pomodoro, Pomodoro after break), reset cycle after long break in FocusBar/Services/TimerService.swift
- [X] T021 [US2] Update TimerViewModel to show current cycle position (e.g., "Session 2/4") and next session type in FocusBar/ViewModels/TimerViewModel.swift
- [X] T022 [US2] Update MenuBarView to display cycle progress indicator and current session type label (Focus / Short Break / Long Break) in FocusBar/Views/MenuBar/MenuBarView.swift

**Checkpoint**: Full Pomodoro cycling works. App transitions automatically between focus and break sessions with correct long break timing.

---

## Phase 5: User Story 3 — Configurable Settings (Priority: P2)

**Goal**: Settings window for timer durations, notification preferences, menu bar display mode, daily goals. All preferences persist via @AppStorage.

**Independent Test**: Open Settings → change Pomodoro to 50 min → close settings → start session → verify 50-min countdown. Quit and relaunch → settings retained.

### Implementation for User Story 3

- [X] T023 [US3] Implement SettingsViewModel as @Observable class with @AppStorage bindings for all UserDefaults keys (timer durations, notification toggles, display mode, daily goal) in FocusBar/ViewModels/SettingsViewModel.swift
- [X] T024 [US3] Implement SettingsView with tabbed layout: Timer tab (durations, sessions until long break), Notifications tab (sound/banner/overlay toggles, sound picker, volume), Display tab (menu bar mode picker), Goals tab (daily Pomodoro goal) in FocusBar/Views/Settings/SettingsView.swift
- [X] T025 [US3] Wire SettingsView into FocusBarApp.swift as a Window scene openable via @Environment(\.openWindow) from MenuBarView in FocusBar/App/FocusBarApp.swift
- [X] T026 [US3] Update TimerService to read durations from UserDefaults instead of hardcoded values in FocusBar/Services/TimerService.swift
- [X] T027 [US3] Update TimerDisplayView to support 3 display modes (icon, timerText, progressBar) based on menuBarDisplayMode preference in FocusBar/Views/MenuBar/TimerDisplayView.swift

**Checkpoint**: All preferences are configurable and persist. Timer uses custom durations. Menu bar shows selected display mode.

---

## Phase 6: User Story 4 — XP, Leveling, and Streak Tracking (Priority: P2)

**Goal**: Earn XP per completed session. Level up through 30 levels. Daily streak counter with freeze support. XP multipliers for streaks and levels.

**Independent Test**: Complete a Pomodoro → verify XP awarded. Complete 4 in a day → verify daily goal bonus + streak increment. Verify level-up notification at XP threshold.

### Implementation for User Story 4

- [X] T028 [P] [US4] Implement GamificationService with GamificationServiceProtocol: calculateXP (base × streak × level multipliers + daily goal bonus), levelForXP lookup against Constants thresholds, evaluateAchievements stub (returns empty for now) in FocusBar/Services/GamificationService.swift
- [X] T029 [P] [US4] Implement StreakService with StreakServiceProtocol: checkAndUpdateStreak (compare lastStreakDate with today), recordDailyGoalMet, useStreakFreeze, resetWeeklyFreezes (ISO week tracking) in FocusBar/Services/StreakService.swift
- [X] T030 [US4] Implement GamificationViewModel as @Observable class: expose currentXP, currentLevel, levelTitle, xpProgress, currentStreak, dailyPomodoroCount; wire to GamificationService and StreakService; update @AppStorage values in FocusBar/ViewModels/GamificationViewModel.swift
- [X] T031 [US4] Create XPProgressView component: level badge, XP bar showing progress to next level, streak counter with flame icon in FocusBar/Views/Components/XPProgressView.swift
- [X] T032 [US4] Wire gamification into TimerViewModel: after session complete → call GamificationService.calculateXP → update DailyStats → check daily goal → update streak → send level-up notification if leveled in FocusBar/ViewModels/TimerViewModel.swift
- [X] T033 [US4] Add XPProgressView and streak display to MenuBarView dropdown in FocusBar/Views/MenuBar/MenuBarView.swift
- [X] T034 [US4] Add level-up and daily goal notifications to NotificationService in FocusBar/Services/NotificationService.swift

**Checkpoint**: XP is awarded and displayed after each session. Levels progress correctly. Streaks track across days with freeze support.

---

## Phase 7: User Story 5 — Achievements System (Priority: P2)

**Goal**: 20+ achievements unlock at milestones. Bonus XP on unlock. Achievements viewable in dedicated panel.

**Independent Test**: Complete first Pomodoro → "First Focus" unlocks with notification. Open achievements panel → see unlocked and locked achievements with progress.

### Implementation for User Story 5

- [X] T035 [US5] Complete GamificationService.evaluateAchievements: check all 20 achievement conditions from Constants definitions against current stats, return newly unlocked achievements, persist Achievement records to SwiftData in FocusBar/Services/GamificationService.swift
- [X] T036 [US5] Implement AchievementsView: grid/list of all achievements grouped by category, unlocked shows date and checkmark, locked shows progress bar toward unlock condition in FocusBar/Views/Achievements/AchievementsView.swift
- [X] T037 [US5] Wire AchievementsView into FocusBarApp.swift as a Window scene openable from MenuBarView in FocusBar/App/FocusBarApp.swift
- [X] T038 [US5] Add achievement unlock notifications to NotificationService in FocusBar/Services/NotificationService.swift
- [X] T039 [US5] Wire achievement evaluation into TimerViewModel post-session flow: after XP calculation → evaluate achievements → persist unlocks → send notifications in FocusBar/ViewModels/TimerViewModel.swift

**Checkpoint**: Achievements unlock correctly at defined milestones. Panel shows all 20+ achievements with progress. Bonus XP is added on unlock.

---

## Phase 8: User Story 6 — Apple Reminders Integration (Priority: P3)

**Goal**: Optionally link Pomodoro sessions to Apple Reminders. Search/select reminders, log focus time to notes, create quick tasks.

**Independent Test**: Grant Reminders permission → search and select a reminder → complete Pomodoro → check reminder notes for logged time. Create quick task → verify it appears in Apple Reminders app.

### Implementation for User Story 6

- [X] T040 [US6] Implement ReminderService with ReminderServiceProtocol: EKEventStore wrapper, requestAccess, fetchReminders, searchReminders, createReminder, appendFocusTime, markComplete, graceful degradation when unauthorized in FocusBar/Services/ReminderService.swift
- [X] T041 [US6] Implement RemindersViewModel as @Observable class: expose reminders list, search query, selected reminder, authorization status; wire to ReminderService in FocusBar/ViewModels/RemindersViewModel.swift
- [X] T042 [US6] Implement ReminderPicker component: searchable dropdown of reminders, "Quick Add Task" text field, permission prompt when unauthorized in FocusBar/Views/Components/ReminderPicker.swift
- [X] T043 [US6] Add ReminderPicker to MenuBarView: show above Start button, link selected reminder to session in FocusBar/Views/MenuBar/MenuBarView.swift
- [X] T044 [US6] Wire reminder integration into TimerViewModel: on session complete with linked reminder → call ReminderService.appendFocusTime, store reminderId/reminderTitle on Session model in FocusBar/ViewModels/TimerViewModel.swift

**Checkpoint**: Reminders can be searched, selected, and linked to sessions. Focus time is logged to reminder notes. Quick task creation works. App works fine without Reminders permission.

---

## Phase 9: User Story 7 — Focus Statistics Dashboard (Priority: P3)

**Goal**: Statistics view with daily/weekly/monthly focus hours, session counts, best day, averages, time-per-task breakdown, and charts.

**Independent Test**: Complete several sessions → open Stats view → verify accurate totals, averages, and charts. Switch between daily/weekly/monthly → data updates correctly.

### Implementation for User Story 7

- [X] T045 [US7] Implement StatsViewModel as @Observable class: compute daily/weekly/monthly totals from SwiftData @Query on Session and DailyStats, best day, average session length, time-per-reminder breakdown, focus-by-hour and focus-by-day-of-week aggregations in FocusBar/ViewModels/StatsViewModel.swift
- [X] T046 [US7] Implement ChartViews using Swift Charts: focus hours bar chart by day, focus distribution by hour-of-day, focus by day-of-week, time-per-task pie/bar chart in FocusBar/Views/Stats/ChartViews.swift
- [X] T047 [US7] Implement StatsView: time range picker (daily/weekly/monthly), summary cards (total hours, sessions, best day, average), chart section, task breakdown table in FocusBar/Views/Stats/StatsView.swift
- [X] T048 [US7] Wire StatsView into FocusBarApp.swift as a Window scene openable from MenuBarView in FocusBar/App/FocusBarApp.swift

**Checkpoint**: Statistics dashboard shows accurate, filterable data. Charts render correctly. Time-per-task breakdown works for linked sessions.

---

## Phase 10: User Story 8 — Data Export (Priority: P3)

**Goal**: Export all user data (sessions, achievements, stats, preferences) to a JSON file.

**Independent Test**: Trigger export from Settings → verify JSON file contains all sessions, achievements, daily stats, and preferences. Validate JSON is well-formed.

### Implementation for User Story 8

- [X] T049 [US8] Implement ExportService with ExportServiceProtocol: query all Sessions, Achievements, DailyStats from SwiftData; collect UserDefaults preferences; encode to JSON; present NSSavePanel; write file in FocusBar/Services/ExportService.swift
- [X] T050 [US8] Add Codable conformance to Session, Achievement, DailyStats models (or create Codable DTOs) for JSON serialization in FocusBar/Models/Session.swift, FocusBar/Models/Achievement.swift, FocusBar/Models/DailyStats.swift
- [X] T051 [US8] Add "Export Data" button to SettingsView that triggers ExportService in FocusBar/Views/Settings/SettingsView.swift

**Checkpoint**: Full data export works. JSON file is well-formed and contains all user data.

---

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T052 [P] Handle force-quit recovery: on app launch, check for incomplete sessions (startTime set, no endTime) and offer to resume or discard in FocusBar/App/FocusBarApp.swift
- [X] T053 [P] Add app icon and accent color assets to FocusBar/Resources/Assets.xcassets/
- [X] T054 [P] Add default notification sound file to FocusBar/Resources/Sounds/
- [X] T055 Verify all edge cases from spec: sleep/wake timer accuracy, clock change handling, permission revocation graceful degradation, max level XP overflow, mid-day goal change
- [X] T056 Memory profiling: verify <50MB idle, <100MB with stats view open
- [X] T057 Run quickstart.md validation: verify build, test, and run commands work correctly

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Foundational — core timer, the MVP
- **US2 (Phase 4)**: Depends on US1 — extends timer with cycling
- **US3 (Phase 5)**: Depends on US1 — settings affect timer behavior
- **US4 (Phase 6)**: Depends on US1 — gamification triggers on session complete
- **US5 (Phase 7)**: Depends on US4 — achievements use GamificationService
- **US6 (Phase 8)**: Depends on US1 — links sessions to reminders
- **US7 (Phase 9)**: Depends on US1 — reads session data for stats
- **US8 (Phase 10)**: Depends on US1 — exports session data
- **Polish (Phase 11)**: Depends on all desired user stories being complete

### User Story Dependencies

- **US1 (P1)**: Foundational → US1 (no other story deps) — **MVP**
- **US2 (P1)**: US1 → US2 (extends TimerService)
- **US3 (P2)**: US1 → US3 (settings wire into timer)
- **US4 (P2)**: US1 → US4 (XP triggers on session complete). Can run in parallel with US2, US3.
- **US5 (P2)**: US4 → US5 (achievements use GamificationService)
- **US6 (P3)**: US1 → US6 (links to sessions). Can run in parallel with US2–US5.
- **US7 (P3)**: US1 → US7 (reads sessions). Can run in parallel with US2–US6.
- **US8 (P3)**: US1 → US8 (exports sessions). Can run in parallel with US2–US7.

### Within Each User Story

- Models before services
- Services before ViewModels
- ViewModels before Views
- Core implementation before wiring into existing views
- Story complete before moving to next priority

### Parallel Opportunities

- Phase 1: T005, T006, T007 can run in parallel (independent files)
- Phase 2: T009, T010 can run in parallel (independent models)
- Phase 6: T028, T029 can run in parallel (independent services)
- After US1 completes: US3, US4, US6, US7, US8 can all start in parallel
- After US4 completes: US5 can start

---

## Parallel Example: User Story 4

```text
# Launch independent services in parallel:
Task T028: "Implement GamificationService in FocusBar/Services/GamificationService.swift"
Task T029: "Implement StreakService in FocusBar/Services/StreakService.swift"

# Then sequentially:
Task T030: "Implement GamificationViewModel" (depends on T028, T029)
Task T031: "Create XPProgressView component" (can parallel with T030)
Task T032: "Wire gamification into TimerViewModel" (depends on T030)
Task T033: "Add XP display to MenuBarView" (depends on T031, T032)
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1 — Core timer with countdown
4. Complete Phase 4: User Story 2 — Auto cycling with breaks
5. **STOP and VALIDATE**: Full Pomodoro technique working end-to-end
6. App is usable as a basic but complete Pomodoro timer

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. US1 + US2 → **MVP: Working Pomodoro timer** (deploy/demo)
3. US3 → **Customizable timer** (deploy/demo)
4. US4 → **Gamified timer with XP and streaks** (deploy/demo)
5. US5 → **Full gamification with achievements** (deploy/demo)
6. US6 → **Task-linked focus sessions** (deploy/demo)
7. US7 → **Productivity analytics** (deploy/demo)
8. US8 → **Data ownership / export** (deploy/demo)
9. Each story adds value without breaking previous stories

### Single Developer Strategy

Work sequentially in priority order:
1. Phase 1 → Phase 2 → Phase 3 (US1) → Phase 4 (US2) = **MVP in ~2 weeks**
2. Phase 5 (US3) → Phase 6 (US4) → Phase 7 (US5) = **Full gamification in ~2 more weeks**
3. Phase 8 (US6) → Phase 9 (US7) → Phase 10 (US8) → Phase 11 = **Complete app in ~2 more weeks**

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable after US1
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- The existing template files (ContentView.swift, Item.swift) are removed in T001
