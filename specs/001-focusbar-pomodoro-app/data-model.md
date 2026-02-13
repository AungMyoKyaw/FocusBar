# Data Model: FocusBar

**Branch**: `001-focusbar-pomodoro-app` | **Date**: 2026-02-14

## Entities

### Session

Represents a single timer period — a Pomodoro, short break, or long break.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | Yes | Unique identifier (auto-generated) |
| startTime | Date | Yes | When the session began |
| endTime | Date | No | When the session ended (nil if in-progress or discarded) |
| duration | Int | Yes | Planned duration in seconds |
| type | SessionType | Yes | pomodoro, shortBreak, or longBreak |
| completed | Bool | Yes | Whether the session ran to completion (default: false) |
| reminderId | String | No | EventKit reminder `calendarItemIdentifier` |
| reminderTitle | String | No | Cached title of linked reminder |
| xpEarned | Int | Yes | XP awarded for this session (0 if incomplete) |

**Relationships**: None (reminder link is a string reference, not a foreign key).

**Validation Rules**:
- `duration` must be > 0
- `endTime` must be >= `startTime` when set
- `xpEarned` must be >= 0
- `type` must be a valid `SessionType` enum value

**State Transitions**:
```
idle → started (startTime set)
started → paused (no model change, tracked in ViewModel)
paused → started (resumed)
started → completed (endTime set, completed = true, xpEarned calculated)
started → discarded (endTime set, completed = false, xpEarned = 0)
```

---

### DailyStats

Pre-aggregated daily summary for fast dashboard queries.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | Yes | Unique identifier (auto-generated) |
| date | Date | Yes | Calendar date (normalized to midnight) |
| pomodorosCompleted | Int | Yes | Count of completed Pomodoro sessions |
| totalFocusMinutes | Int | Yes | Sum of completed Pomodoro durations in minutes |
| streakMaintained | Bool | Yes | Whether daily goal was met |
| xpEarned | Int | Yes | Total XP earned this day |

**Validation Rules**:
- `date` must be unique (one record per calendar day)
- All integer fields must be >= 0

**Update Trigger**: After each completed session, upsert the DailyStats record for the current date.

---

### Achievement

Tracks unlocked milestones.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | Yes | Unique identifier (auto-generated) |
| type | String | Yes | Achievement identifier (e.g., "first_focus", "week_warrior") |
| unlockedAt | Date | Yes | When the achievement was earned |
| metadata | String | No | JSON-encoded contextual data (e.g., streak count at unlock) |

**Validation Rules**:
- `type` must be unique (each achievement unlocked at most once)
- `type` must match a defined achievement identifier

---

### SessionType (Enum)

| Value | Raw Value | Description |
|-------|-----------|-------------|
| pomodoro | "pomodoro" | Focus session |
| shortBreak | "shortBreak" | Short rest period |
| longBreak | "longBreak" | Extended rest period |

---

### UserProfile (UserDefaults — not a SwiftData model)

Scalar preferences and gamification state stored in `UserDefaults` / `@AppStorage`.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| pomodoroDuration | Int | 25 | Focus session duration (minutes) |
| shortBreakDuration | Int | 5 | Short break duration (minutes) |
| longBreakDuration | Int | 15 | Long break duration (minutes) |
| sessionsUntilLongBreak | Int | 4 | Pomodoros before long break |
| menuBarDisplayMode | String | "timerText" | One of: icon, timerText, progressBar |
| soundEnabled | Bool | false | Play sound on session end |
| bannerEnabled | Bool | true | Show notification banner |
| overlayEnabled | Bool | false | Show screen overlay on break |
| soundFile | String | "default" | Selected notification sound |
| currentXP | Int | 0 | Total accumulated XP |
| currentLevel | Int | 1 | Current level (1–30) |
| currentStreak | Int | 0 | Consecutive days meeting goal |
| lastStreakDate | String | "" | ISO 8601 date of last goal-met day |
| streakFreezesRemaining | Int | 1 | Weekly streak freezes |
| lastFreezeResetWeek | Int | 0 | ISO week number of last freeze reset |
| dailyGoal | Int | 4 | Pomodoros needed to maintain streak |

## Entity Relationships Diagram

```
┌─────────────┐
│   Session    │
│              │───── reminderId (string ref) ──→ Apple Reminders (external)
│              │
└──────┬───────┘
       │ aggregated into
       ▼
┌─────────────┐
│ DailyStats  │
│              │
└──────────────┘

┌─────────────┐
│ Achievement  │ (standalone, evaluated from Session + DailyStats data)
└──────────────┘

┌─────────────┐
│ UserProfile  │ (UserDefaults, drives TimerService + GamificationService)
└──────────────┘
```

## XP Level Thresholds

| Level | Title | XP Required |
|-------|-------|-------------|
| 1 | Seedling | 0 |
| 2 | Sprout | 250 |
| 3 | Sapling | 600 |
| 4 | Young Tree | 1,000 |
| 5 | Growing Tree | 1,500 |
| 6 | Sturdy Tree | 2,100 |
| 7 | Tall Tree | 2,800 |
| 8 | Leafy Tree | 3,600 |
| 9 | Branching Tree | 4,500 |
| 10 | Mighty Oak | 5,000 |
| 11 | Elder Oak | 5,800 |
| 12 | Wise Oak | 6,800 |
| 13 | Deep Roots | 8,000 |
| 14 | Forest Keeper | 9,500 |
| 15 | Ancient Grove | 12,000 |
| 16 | Grove Warden | 14,500 |
| 17 | Woodland Sage | 17,500 |
| 18 | Nature's Voice | 20,500 |
| 19 | Elder Spirit | 23,000 |
| 20 | Forest Guardian | 25,000 |
| 21 | Timeless Oak | 28,000 |
| 22 | Eternal Roots | 32,000 |
| 23 | Spirit Walker | 37,000 |
| 24 | Ancient Wisdom | 43,000 |
| 25 | Nature Spirit | 50,000 |
| 26 | Cosmic Seed | 60,000 |
| 27 | Stellar Grove | 72,000 |
| 28 | Celestial Oak | 85,000 |
| 29 | Infinite Focus | 92,000 |
| 30 | Focus Master | 100,000 |

## Achievement Definitions

| ID | Title | Category | Condition | XP Bonus |
|----|-------|----------|-----------|----------|
| first_focus | First Focus | Getting Started | Complete 1 Pomodoro | 10 |
| dip_your_toes | Dip Your Toes | Getting Started | Complete 5 Pomodoros | 25 |
| getting_serious | Getting Serious | Getting Started | Complete 25 Pomodoros | 50 |
| week_warrior | Week Warrior | Consistency | 7-day streak | 100 |
| fortnight_fighter | Fortnight Fighter | Consistency | 14-day streak | 200 |
| monthly_master | Monthly Master | Consistency | 30-day streak | 500 |
| century_club | Century Club | Volume | 100 total Pomodoros | 150 |
| five_hundred_club | Five Hundred Club | Volume | 500 total Pomodoros | 500 |
| thousand_club | Thousand Club | Volume | 1,000 total Pomodoros | 1,000 |
| half_day | Half Day | Daily Intensity | 4 Pomodoros in one day | 50 |
| marathon | Marathon | Daily Intensity | 8 Pomodoros in one day | 100 |
| iron_focus | Iron Focus | Daily Intensity | 12 Pomodoros in one day | 200 |
| night_owl | Night Owl | Time Based | Session between 12–4 AM | 25 |
| early_bird | Early Bird | Time Based | Session between 5–7 AM | 25 |
| weekend_warrior | Weekend Warrior | Time Based | 20 sessions on weekends | 100 |
| task_master | Task Master | Task Mastery | Link 10 sessions to reminders | 50 |
| project_pro | Project Pro | Task Mastery | 50 linked sessions completed | 150 |
| streak_saver | Streak Saver | Consistency | Use first streak freeze | 15 |
| level_five | Rising Star | Getting Started | Reach level 5 | 75 |
| level_ten | Mighty Achiever | Getting Started | Reach level 10 | 200 |
