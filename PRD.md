# FocusBar - Product Requirements Document (PRD)

## 1. Executive Summary

### Problem Statement
Knowledge workers struggle with maintaining focus in an era of constant digital distractions. Existing Pomodoro timers are either too simplistic, lack task integration, or require cloud accounts that compromise privacy.

### Proposed Solution
FocusBar is a **native macOS menu bar Pomodoro timer** that combines minimalist design with powerful task management through Apple Reminders integration. It offers deep gamification for motivation while keeping all data local-first for maximum privacy.

### Success Criteria
- 1,000+ GitHub stars within 6 months of launch
- 4.5+ star rating on Product Hunt
- < 50MB memory footprint during idle
- Timer accuracy within ±1 second over 25-minute sessions
- 90%+ of users retain streak data after 30 days

---

## 2. User Experience & Functionality

### User Personas

| Persona | Description | Primary Need |
|---------|-------------|--------------|
| **Deep Worker** | Software developer, writer, researcher | Distraction-free focus sessions |
| **Student** | University/college student | Study discipline + motivation |
| **Remote Professional** | WFH employee needing structure | Time-boxed work with breaks |
| **ADHD User** | Neurodivergent individuals | External accountability + gamification |

### User Stories

#### Core Timer
| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-001 | As a user, I want to start a Pomodoro with one click so I can focus immediately. | - Single click from menu bar starts 25-min timer<br>- Visual feedback confirms timer started<br>- Timer visible in menu bar |
| US-002 | As a user, I want to see live countdown in the menu bar so I know remaining time at a glance. | - Display format: "🍅 18:32" or progress bar<br>- Updates every second<br>- Configurable display mode |
| US-003 | As a user, I want to pause/resume my timer so I can handle interruptions. | - Click to pause (timer highlights paused state)<br>- Click again to resume<br>- Long-press or right-click to reset |
| US-004 | As a user, I want to skip or reset a session when needed. | - Right-click menu shows "Skip" and "Reset"<br>- Confirmation dialog for reset (optional setting) |

#### Task Integration (Apple Reminders)
| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-005 | As a user, I want to link my Pomodoro to an Apple Reminder so I track work on specific tasks. | - Dropdown shows recent Apple Reminders<br>- Search/filter reminders list<br>- Selected reminder shows during session |
| US-006 | As a user, I want completed Pomodoros to update my task progress automatically. | - Optional auto-complete reminder after N sessions<br>- Focus time logged to reminder notes<br>- Stats show time per task |
| US-007 | As a user, I want to create quick tasks without leaving FocusBar. | - "Quick Add Task" field in menu<br>- Task created in default Apple Reminders list<br>- Immediate selection for current session |

#### Gamification
| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-008 | As a user, I want to earn XP for completed sessions so I feel motivated to continue. | - 25 XP per completed Pomodoro<br>- 5 XP per completed short break<br>- 15 XP per completed long break<br>- XP multiplier for streaks |
| US-009 | As a user, I want to build daily streaks so I maintain consistency. | - Daily goal: 4+ Pomodoros maintains streak<br>- Streak counter visible in menu<br>- Streak freeze (1 per week) for missed days |
| US-010 | As a user, I want to unlock achievements for milestones so I feel rewarded. | - "First Focus" - Complete 1 Pomodoro<br>- "Week Warrior" - 7-day streak<br>- "Century Club" - 100 Pomodoros<br>- "Marathon Master" - 8 Pomodoros in one day<br>- 20+ achievements at launch |
| US-011 | As a user, I want to see my focus statistics so I understand my productivity patterns. | - Daily/weekly/monthly focus hours<br>- Best day, average session length<br- Charts: focus time by hour, by day of week<br>- Task breakdown: time per project |

#### Notifications
| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-012 | As a user, I want customizable notifications when sessions end. | - Sound alert (configurable, multiple options)<br>- macOS notification banner<br>- Optional screen overlay during break<br>- All notification types individually togglable |
| US-013 | As a user, I want FocusBar to be silent by default so it doesn't disturb others. | - Default: silent mode enabled<br>- Sound volume configurable<br>- "Do Not Disturb" mode respects system settings |

### Non-Goals (What We're NOT Building)

| Non-Goal | Reason |
|----------|--------|
| Cloud sync / user accounts | Privacy-first, local-only approach |
| Windows / Linux / Mobile support | Focus on native macOS excellence first |
| Team features / collaboration | Individual productivity focus |
| Third-party task apps (Todoist, etc.) | Apple Reminders integration only - keeps app simple |
| AI-powered features | Keep app deterministic and fast |
| Calendar integration | Scope management - may revisit in v2.0 |

---

## 3. Technical Specifications

### Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    FocusBar App                         │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Menu Bar   │  │   Settings   │  │    Stats     │  │
│  │    View      │  │     View     │  │    View      │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                 │          │
│  ┌──────┴─────────────────┴─────────────────┴───────┐  │
│  │              ViewModel (ObservableObject)        │  │
│  └──────────────────────┬───────────────────────────┘  │
│                         │                              │
│  ┌──────────────────────┼───────────────────────────┐  │
│  │              Service Layer                        │  │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐   │  │
│  │  │   Timer    │ │  Gamification│ │  Reminder │   │  │
│  │  │  Service   │ │   Service   │ │  Service  │   │  │
│  │  └────────────┘ └────────────┘ └────────────┘   │  │
│  └──────────────────────┬───────────────────────────┘  │
│                         │                              │
│  ┌──────────────────────┴───────────────────────────┐  │
│  │              Data Persistence                     │  │
│  │  ┌──────────────┐      ┌──────────────────────┐  │  │
│  │  │  Core Data   │      │    UserDefaults      │  │  │
│  │  │ (Sessions,   │      │ (Preferences, Stats) │  │  │
│  │  │  Achievements)│     └──────────────────────┘  │  │
│  │  └──────────────┘                                 │  │
│  └──────────────────────────────────────────────────┘  │
│                         │                              │
│  ┌──────────────────────┴───────────────────────────┐  │
│  │           Apple Frameworks                        │  │
│  │  EventKit (Reminders) │ UserNotifications        │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Technology Stack

| Component | Technology | Rationale |
|-----------|------------|-----------|
| Language | Swift 5.9+ | Native performance, modern concurrency |
| UI Framework | SwiftUI | Declarative, rapid development |
| Minimum macOS | macOS 13.0 (Ventura) | Menu bar extras API, modern SwiftUI |
| Database | Core Data + UserDefaults | Structured session storage + simple prefs |
| Task Integration | EventKit | Native Apple Reminders access |
| Notifications | UserNotifications | System integration |
| Concurrency | Swift Async/Await | Modern, readable async code |

### Data Models

#### Core Data Entities

```
Session {
  id: UUID
  startTime: Date
  endTime: Date
  duration: Int (seconds)
  type: Enum (pomodoro, shortBreak, longBreak)
  completed: Bool
  reminderId: String? (optional, links to Apple Reminder)
  reminderTitle: String?
  xpEarned: Int
}

DailyStats {
  id: UUID
  date: Date
  pomodorosCompleted: Int
  totalFocusMinutes: Int
  streakMaintained: Bool
  xpEarned: Int
}

Achievement {
  id: UUID
  type: String
  unlockedAt: Date
  metadata: JSON?
}
```

#### UserDefaults Keys

```swift
// Preferences
"focusBar.timer.pomodoroDuration"      // Int (default: 25)
"focusBar.timer.shortBreakDuration"    // Int (default: 5)
"focusBar.timer.longBreakDuration"     // Int (default: 15)
"focusBar.timer.sessionsUntilLongBreak" // Int (default: 4)

// Display
"focusBar.display.menuBarMode"         // Enum (icon, timerText, progressBar)
"focusBar.display.showIcon"            // Bool

// Notifications
"focusBar.notifications.soundEnabled"  // Bool (default: false)
"focusBar.notifications.bannerEnabled" // Bool (default: true)
"focusBar.notifications.overlayEnabled" // Bool (default: false)
"focusBar.notifications.soundFile"     // String

// Gamification
"focusBar.gamification.currentXP"      // Int
"focusBar.gamification.currentLevel"   // Int
"focusBar.gamification.currentStreak"  // Int
"focusBar.gamification.streakFreezes"  // Int (default: 1 per week)
"focusBar.gamification.dailyGoal"      // Int (default: 4)
```

### Integration Points

#### Apple Reminders (EventKit)

```swift
// Required Entitlements
com.apple.security.app-sandbox = true
com.apple.security.personal-information.addressbook = false
com.apple.security.personal-information.calendars = false
com.apple.security.personal-information.reminders = true

// Access Flow
1. Request EKEventStore authorization on first launch
2. Fetch lists and reminders on demand
3. Create quick tasks in default list
4. Update reminder notes with focus time
5. Optionally mark reminders complete
```

### Performance Requirements

| Metric | Target | Measurement |
|--------|--------|-------------|
| App Launch Time | < 500ms | Time to menu bar icon visible |
| Memory (Idle) | < 50MB | Activity Monitor baseline |
| Memory (Active) | < 100MB | During stats view rendering |
| Timer Accuracy | ±1 sec | Tested over 25-min session |
| Battery Impact | Negligible | < 0.5% per hour |
| Database Queries | < 10ms | Core Data fetch operations |

---

## 4. Gamification System

### XP & Leveling

| Level | XP Required | Title |
|-------|-------------|-------|
| 1 | 0 | Seedling |
| 2 | 250 | Sprout |
| 3 | 600 | Sapling |
| 4 | 1,000 | Young Tree |
| 5 | 1,500 | Growing Tree |
| 10 | 5,000 | Mighty Oak |
| 15 | 12,000 | Ancient Grove |
| 20 | 25,000 | Forest Guardian |
| 25 | 50,000 | Nature Spirit |
| 30 | 100,000 | Focus Master |

### XP Calculation

```
Base XP:
- Completed Pomodoro (25 min): 25 XP
- Completed Short Break: 5 XP
- Completed Long Break: 15 XP

Modifiers:
- Streak Multiplier: 1 + (streakDays × 0.05), max 2.0
- Daily Goal Bonus: +50 XP when hitting daily goal
- Level Bonus: +5% per level

Example:
- Day 10, Level 5, completing 4th Pomodoro of the day
- Base: 25 XP
- Streak (10 days): 25 × 1.5 = 37.5 XP
- Level (5): 37.5 × 1.25 = 46.875 XP
- Daily Goal Bonus: +50 XP
- Total: ~97 XP
```

### Achievements

| Category | Achievement | Requirement | XP Bonus |
|----------|-------------|-------------|----------|
| **Getting Started** | First Focus | Complete 1 Pomodoro | 10 |
| | Dip Your Toes | Complete 5 Pomodoros | 25 |
| | Getting Serious | Complete 25 Pomodoros | 50 |
| **Consistency** | Week Warrior | 7-day streak | 100 |
| | Fortnight Fighter | 14-day streak | 200 |
| | Monthly Master | 30-day streak | 500 |
| **Volume** | Century Club | 100 Pomodoros total | 150 |
| | Five Hundred Club | 500 Pomodoros total | 500 |
| | Thousand Club | 1,000 Pomodoros total | 1,000 |
| **Daily Intensity** | Half Day | 4 Pomodoros in one day | 50 |
| | Marathon | 8 Pomodoros in one day | 100 |
| | Iron Focus | 12 Pomodoros in one day | 200 |
| **Time Based** | Night Owl | Complete session between 12-4 AM | 25 |
| | Early Bird | Complete session between 5-7 AM | 25 |
| | Weekend Warrior | 20 sessions on weekends | 100 |
| **Task Mastery** | Task Master | Link 10 sessions to reminders | 50 |
| | Project Pro | Complete 50 linked sessions | 150 |

---

## 5. Security & Privacy

### Data Handling

| Principle | Implementation |
|-----------|----------------|
| **Local-First** | All data stored locally in Application Support |
| **No Telemetry** | Zero analytics, no crash reporting to external servers |
| **No Accounts** | No email, passwords, or authentication required |
| **Export Control** | User owns data, full export to JSON available |
| **Sandbox Compliance** | App runs in macOS sandbox with minimal entitlements |

### Permissions Required

| Permission | Purpose | Required |
|------------|---------|----------|
| Reminders (EventKit) | Link sessions to tasks | Optional - app works without it |
| Notifications | Session end alerts | Optional - silent mode available |

### Data Storage Location

```
~/Library/Containers/com.focusbar.app/
├── Data/
│   ├── Library/
│   │   ├── Application Support/
│   │   │   └── FocusBar/
│   │   │       ├── FocusBar.sqlite      # Core Data store
│   │   │       ├── FocusBar.sqlite-wal
│   │   │       └── FocusBar.sqlite-shm
│   │   └── Preferences/
│   │       └── com.focusbar.app.plist   # UserDefaults
│   └── export/                           # User exports
│       └── focusbar-export-YYYY-MM-DD.json
```

---

## 6. Risks & Mitigation

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Timer drift on sleep/wake | Medium | High | Use monotonic clock, validate on wake |
| Core Data migration issues | Low | Medium | Lightweight migration, versioned models |
| EventKit permission denial | Medium | Low | Graceful degradation, clear messaging |
| Memory leak in long-running sessions | Low | Medium | Instrument profiling, autorelease pools |

### Product Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Feature creep (gamification overkill) | Medium | Medium | Strict MVP scope, user feedback loops |
| Apple Reminders API changes | Low | Medium | Abstract EventKit layer, monitor beta releases |
| Low adoption (crowded market) | Medium | High | Focus on differentiation: privacy + Apple integration |

---

## 7. Roadmap

### MVP (v1.0) - Target: 8 weeks

| Week | Deliverables |
|------|--------------|
| 1-2 | Core timer, menu bar UI, state management |
| 3-4 | Settings view, notification system, basic stats |
| 5-6 | EventKit integration, task linking |
| 7 | Gamification (XP, levels, achievements) |
| 8 | Polish, testing, documentation, launch prep |

**MVP Features:**
- [x] Classic 25/5 Pomodoro timer
- [x] Menu bar with live countdown
- [x] Pause/resume/reset
- [x] Configurable durations
- [x] Sound + notification alerts
- [x] Apple Reminders integration
- [x] Basic stats (daily/weekly focus time)
- [x] XP system + levels
- [x] Streak tracking
- [x] 10 core achievements

### v1.1 - Target: +4 weeks

- Advanced statistics with charts
- 10 additional achievements
- Export data to JSON
- Custom notification sounds
- Menu bar display mode options

### v1.2 - Target: +6 weeks

- Widget support (macOS Sonoma)
- Shortcuts integration
- Apple Watch companion app
- Focus mode integration

### v2.0 - Target: +12 weeks

- Calendar integration (view focus sessions in Calendar)
- Project/tag-based organization
- Advanced analytics with insights
- Theme customization

---

## 8. Open Source Strategy

### Repository Structure

```
focusbar/
├── FocusBar.xcodeproj
├── FocusBar/
│   ├── App/
│   ├── Views/
│   ├── ViewModels/
│   ├── Services/
│   ├── Models/
│   └── Resources/
├── FocusBarTests/
├── FocusBarUITests/
├── Docs/
│   ├── ARCHITECTURE.md
│   ├── CONTRIBUTING.md
│   └── CHANGELOG.md
├── LICENSE (MIT)
└── README.md
```

### License
**MIT License** - Maximum freedom for users and contributors

### Community
- GitHub Discussions for Q&A
- GitHub Issues for bug reports and features
- GitHub Sponsors / Ko-fi for donations

---

## 9. Appendix

### Competitive Analysis

| App | Platform | Strengths | Weaknesses |
|-----|----------|-----------|------------|
| Pomodoro Timer Lite | macOS | Simple, free | No task integration, basic UI |
| Be Focused | macOS/iOS | Apple ecosystem | Paid, cloud required |
| Forest | iOS/Android | Gamification | Mobile only, not native macOS |
| PomoDone | Cross-platform | Task integrations | Subscription, complex |
| Session | macOS | Beautiful UI | Paid, no gamification |

### FocusBar Differentiation
1. **Privacy-first**: No cloud, no accounts, all data local
2. **Native experience**: Built specifically for macOS menu bar
3. **Apple integration**: Deep Apple Reminders support
4. **Free + Open source**: MIT licensed, community-driven
5. **Gamification depth**: XP, levels, achievements, streaks

---

*Document Version: 1.0*
*Last Updated: February 2026*
*Author: FocusBar Team*
