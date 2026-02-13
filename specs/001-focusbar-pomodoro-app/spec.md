# Feature Specification: FocusBar — macOS Menu Bar Pomodoro Timer

**Feature Branch**: `001-focusbar-pomodoro-app`  
**Created**: 2026-02-14  
**Status**: Draft  
**Input**: User description: "Implement complete FocusBar macOS menu bar Pomodoro timer with task integration, gamification, and local-first privacy as described in PRD.md"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Start and Complete a Pomodoro Session (Priority: P1)

A user clicks the FocusBar icon in the macOS menu bar and starts a 25-minute focus session with one click. A live countdown ("🍅 18:32") appears in the menu bar, updating every second. When the session ends, a notification informs the user, and the app automatically transitions to a short break.

**Why this priority**: The core timer is the fundamental value proposition. Without a working Pomodoro timer, nothing else matters.

**Independent Test**: Can be fully tested by launching the app, clicking "Start", and observing the countdown complete — delivers immediate focus-timing value.

**Acceptance Scenarios**:

1. **Given** the app is running in the menu bar and no session is active, **When** the user clicks the menu bar icon and selects "Start Focus", **Then** a 25-minute countdown begins and the menu bar displays live remaining time.
2. **Given** a Pomodoro session is running, **When** the countdown reaches 00:00, **Then** the session is recorded as completed, a notification is shown, and a short break countdown begins automatically.
3. **Given** a Pomodoro session is running, **When** the user clicks the timer, **Then** the session pauses with a visual indication of the paused state.
4. **Given** a paused session exists, **When** the user clicks the timer again, **Then** the session resumes from where it was paused.
5. **Given** a session is running or paused, **When** the user right-clicks and selects "Reset", **Then** the session is discarded and the timer returns to idle state.
6. **Given** a session is running, **When** the user right-clicks and selects "Skip", **Then** the current session ends immediately and the next phase (break or focus) begins.

---

### User Story 2 — Automatic Session Cycling with Breaks (Priority: P1)

After completing a Pomodoro, the app automatically starts a short break (5 minutes). After every 4 Pomodoros, a long break (15 minutes) is offered instead. The user can customize all durations and the number of sessions before a long break.

**Why this priority**: The Pomodoro technique is defined by its work-break rhythm. Without automatic cycling, the timer is just a simple countdown.

**Independent Test**: Can be tested by completing 4 consecutive Pomodoros and verifying the break pattern (short, short, short, long) triggers correctly.

**Acceptance Scenarios**:

1. **Given** a Pomodoro just completed and fewer than 4 sessions since last long break, **When** the session ends, **Then** a 5-minute short break begins automatically.
2. **Given** the 4th Pomodoro in a cycle just completed, **When** the session ends, **Then** a 15-minute long break begins automatically and the cycle counter resets.
3. **Given** the user has set custom durations (e.g., 50/10/30), **When** sessions run, **Then** the custom durations are used instead of defaults.

---

### User Story 3 — Configurable Settings (Priority: P2)

The user opens a Settings window from the menu bar dropdown to customize timer durations, notification preferences, menu bar display mode, and daily goals. All preferences persist across app restarts.

**Why this priority**: Personalization is essential for different work styles, but the app is usable with sensible defaults.

**Independent Test**: Can be tested by changing each setting, restarting the app, and verifying preferences persist.

**Acceptance Scenarios**:

1. **Given** the user is in the Settings view, **When** they change the Pomodoro duration to 50 minutes and close settings, **Then** the next Pomodoro session uses the 50-minute duration.
2. **Given** the user enables sound notifications, **When** a session ends, **Then** an audio alert plays at the configured volume.
3. **Given** the user sets the menu bar display to "progress bar" mode, **When** a session is running, **Then** the menu bar shows a visual progress indicator instead of text.
4. **Given** the user changes any setting, **When** the app is quit and relaunched, **Then** all settings retain their updated values.

---

### User Story 4 — XP, Leveling, and Streak Tracking (Priority: P2)

After completing each session, the user earns XP. XP accumulates toward levels (Seedling → Focus Master). A daily streak counter tracks consecutive days of meeting the daily Pomodoro goal (default: 4). Streak multipliers increase XP earnings.

**Why this priority**: Gamification drives long-term engagement and retention — a key differentiator from competitors. But the timer must work first.

**Independent Test**: Can be tested by completing sessions and verifying XP accumulation, level progression, and streak counter updates.

**Acceptance Scenarios**:

1. **Given** the user completes a 25-minute Pomodoro, **When** the session ends, **Then** 25 base XP is earned (modified by streak and level multipliers) and the total is displayed.
2. **Given** the user has a 10-day streak and is level 5, **When** they complete a Pomodoro, **Then** XP is calculated as: base × streak multiplier (1.5) × level multiplier (1.25).
3. **Given** the user completes their 4th Pomodoro of the day (daily goal), **When** the goal is met, **Then** a +50 XP daily goal bonus is awarded and a congratulatory notification appears.
4. **Given** the user met their daily goal yesterday but not today (before midnight), **When** midnight passes without meeting the goal, **Then** the streak resets to 0 unless a streak freeze is available and auto-applied.
5. **Given** the user has accumulated enough XP to reach the next level, **When** the threshold is crossed, **Then** the user levels up with a celebratory notification showing the new title.

---

### User Story 5 — Achievements System (Priority: P2)

The user earns achievements for reaching milestones (first Pomodoro, 7-day streak, 100 total sessions, etc.). Achievements award bonus XP and are viewable in a dedicated achievements panel.

**Why this priority**: Achievements provide additional motivation milestones beyond the leveling system.

**Independent Test**: Can be tested by triggering each achievement condition and verifying unlock notification and XP bonus.

**Acceptance Scenarios**:

1. **Given** the user completes their very first Pomodoro, **When** the session ends, **Then** the "First Focus" achievement unlocks with a notification and +10 bonus XP.
2. **Given** the user opens the achievements panel, **When** viewing achievements, **Then** unlocked achievements show with unlock date, and locked achievements show progress toward unlock.
3. **Given** the user reaches a 7-day streak, **When** the 7th consecutive daily goal is met, **Then** the "Week Warrior" achievement unlocks with +100 bonus XP.

---

### User Story 6 — Apple Reminders Integration (Priority: P3)

Before starting a Pomodoro, the user can optionally link the session to an Apple Reminder. The app shows a searchable dropdown of reminders. After sessions, focus time is logged to the reminder's notes. Users can also create quick tasks without leaving the app.

**Why this priority**: Task linking adds significant value but is entirely optional — the core timer and gamification work independently.

**Independent Test**: Can be tested by granting Reminders permission, linking a session to a reminder, completing it, and checking the reminder's notes for logged time.

**Acceptance Scenarios**:

1. **Given** the user has granted Reminders permission, **When** they click the task selector before starting a session, **Then** a searchable dropdown of Apple Reminders appears.
2. **Given** the user selected a reminder and completed a Pomodoro, **When** the session ends, **Then** the focus time is appended to the reminder's notes (e.g., "FocusBar: 25 min on 2026-02-14").
3. **Given** the user has not granted Reminders permission, **When** they try to access task linking, **Then** a clear message explains how to grant permission, and the rest of the app works normally.
4. **Given** the user types in the "Quick Add Task" field, **When** they press Enter, **Then** a new reminder is created in the default Apple Reminders list and immediately available for session linking.
5. **Given** the user has configured auto-complete after N sessions, **When** N linked sessions for a reminder are completed, **Then** the reminder is optionally marked as complete in Apple Reminders.

---

### User Story 7 — Focus Statistics Dashboard (Priority: P3)

The user opens a statistics view showing daily, weekly, and monthly focus hours, session counts, best day, average session length, and time-per-task breakdown. Visual charts show focus patterns by hour and day of week.

**Why this priority**: Statistics provide valuable self-reflection but are a read-only view of data already being collected by higher-priority stories.

**Independent Test**: Can be tested by completing several sessions over multiple days and verifying the stats view renders accurate summaries and charts.

**Acceptance Scenarios**:

1. **Given** the user has completed sessions over the past week, **When** they open the Stats view, **Then** they see daily and weekly focus hour totals, session counts, and average session length.
2. **Given** the user has linked sessions to reminders, **When** viewing stats, **Then** a task breakdown shows time spent per reminder/project.
3. **Given** the user switches between daily/weekly/monthly views, **When** selecting a time range, **Then** all metrics and charts update to reflect that range.

---

### User Story 8 — Data Export (Priority: P3)

The user can export all their focus data (sessions, achievements, stats) to a JSON file for backup or analysis.

**Why this priority**: Data ownership is a core privacy principle, but it's a utility feature with low day-to-day usage.

**Independent Test**: Can be tested by triggering an export and validating the JSON contains all session records, achievements, and stats.

**Acceptance Scenarios**:

1. **Given** the user selects "Export Data" from settings, **When** the export completes, **Then** a JSON file is saved containing all sessions, achievements, daily stats, and preferences.
2. **Given** the user has 1,000+ sessions, **When** exporting, **Then** the export completes within 5 seconds and the file is well-formed JSON.

---

### Edge Cases

- What happens when the Mac goes to sleep mid-session? The timer must detect sleep/wake events and either pause the session or adjust the remaining time based on elapsed wall-clock time.
- What happens when the user changes system clock mid-session? The timer should use monotonic time to remain accurate regardless of clock changes.
- What happens when Reminders permission is revoked after sessions were linked? Previously logged data remains intact; future linking gracefully shows a re-authorization prompt.
- What happens when the user reaches the maximum XP/level? XP continues to accumulate; the user retains the highest title ("Focus Master") with no further level notifications.
- What happens when the daily goal is changed mid-day? The new goal applies immediately; if already met under the old goal, the streak is maintained.
- What happens when the app is force-quit during an active session? On next launch, detect the incomplete session from the last recorded start time and offer to resume or discard.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a persistent icon in the macOS menu bar that provides one-click access to start a Pomodoro session.
- **FR-002**: System MUST show a live countdown in the menu bar, updating every second, in configurable formats (icon + time text, progress bar, or icon only).
- **FR-003**: System MUST support pause, resume, skip, and reset actions for the active session.
- **FR-004**: System MUST automatically cycle between Pomodoro, short break, and long break sessions according to the configured pattern (default: 4 Pomodoros then long break).
- **FR-005**: System MUST allow users to configure timer durations (Pomodoro, short break, long break) and sessions-until-long-break count.
- **FR-006**: System MUST persist all user preferences across app restarts.
- **FR-007**: System MUST send configurable notifications at session end (sound alert, system notification banner, optional screen overlay), all individually togglable with silent mode as default.
- **FR-008**: System MUST award XP for completed sessions (25 XP per Pomodoro, 5 XP per short break, 15 XP per long break) with streak and level multipliers.
- **FR-009**: System MUST track daily streaks based on meeting a configurable daily Pomodoro goal (default: 4), with streak freeze capability (1 per week).
- **FR-010**: System MUST support a leveling system with 30 levels (Seedling to Focus Master) with defined XP thresholds.
- **FR-011**: System MUST track and award at least 20 achievements across categories (getting started, consistency, volume, daily intensity, time-based, task mastery).
- **FR-012**: System MUST store all session data, achievements, and statistics locally with no external network calls or telemetry.
- **FR-013**: System MUST integrate with Apple Reminders via EventKit to allow linking sessions to reminders, creating quick tasks, and logging focus time to reminder notes.
- **FR-014**: System MUST provide a statistics view showing daily/weekly/monthly focus hours, session counts, best day, average session length, and time-per-task breakdown.
- **FR-015**: System MUST support exporting all user data (sessions, achievements, stats, preferences) to a JSON file.
- **FR-016**: System MUST use monotonic time for timer accuracy, handling sleep/wake and system clock changes correctly.
- **FR-017**: System MUST run within the macOS app sandbox with minimal entitlements (Reminders access optional, Notifications optional).
- **FR-018**: System MUST gracefully degrade when optional permissions (Reminders, Notifications) are not granted.

### Key Entities

- **Session**: Represents a single timer period (Pomodoro, short break, or long break). Tracks start time, end time, duration, completion status, type, linked reminder reference, and XP earned.
- **DailyStats**: Aggregated daily record of Pomodoros completed, total focus minutes, streak status, and XP earned for a given date.
- **Achievement**: Represents a milestone unlock. Tracks achievement type, unlock date, and optional metadata (e.g., streak count at time of unlock).
- **UserProfile** (virtual, stored in preferences): Tracks current XP, level, streak count, streak freezes remaining, and all user preferences.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can start a focus session within 2 seconds of clicking the menu bar icon.
- **SC-002**: Timer countdown remains accurate within ±1 second over a 25-minute session, including through sleep/wake cycles.
- **SC-003**: The app uses less than 50 MB of memory when idle and less than 100 MB when displaying statistics.
- **SC-004**: App launches and shows the menu bar icon in under 500 milliseconds.
- **SC-005**: 90% of first-time users can complete their first Pomodoro session without consulting documentation.
- **SC-006**: Users who engage with gamification features (XP, streaks, achievements) show 30-day retention rate of 90%+.
- **SC-007**: Data export completes within 5 seconds for users with up to 1,000 sessions.
- **SC-008**: The app consumes less than 0.5% battery per hour during active use.
- **SC-009**: All user data remains exclusively on the local device with zero network requests.
- **SC-010**: Users can link a session to an Apple Reminder and see logged focus time within 3 seconds of session completion.

## Assumptions

- Users are on macOS 13.0 (Ventura) or later, which supports MenuBarExtra and modern SwiftUI APIs.
- The app targets individual productivity; no multi-user or collaboration features are needed.
- Apple Reminders is the only task management integration; third-party apps (Todoist, Things, etc.) are out of scope.
- Silent mode is the default notification behavior; users opt in to sounds.
- The leveling system uses fixed XP thresholds (not dynamically adjusted).
- Streak freeze is automatically applied if available; the user does not manually trigger it.
- All charts and statistics are rendered locally with no dependency on external charting services.
- The MIT license is chosen for open-source distribution.
