# Service Contracts: FocusBar

**Branch**: `001-focusbar-pomodoro-app` | **Date**: 2026-02-14

Since FocusBar is a native macOS app (not a web service), contracts define the **internal service interfaces** — the public API surface of each service class that ViewModels depend on.

---

## TimerService

Manages the countdown timer, session state, and sleep/wake handling.

```swift
protocol TimerServiceProtocol {
    var state: TimerState { get }              // .idle, .running, .paused, .completed
    var remainingSeconds: Int { get }          // Seconds left in current session
    var currentSessionType: SessionType { get } // pomodoro, shortBreak, longBreak
    var completedPomodorosInCycle: Int { get }  // 0–N, resets after long break
    
    func start()                               // Begin or resume session
    func pause()                               // Pause active session
    func reset()                               // Discard current session, return to idle
    func skip()                                // End current session, advance to next phase
    
    var onSessionComplete: ((SessionType, Int) -> Void)? { get set }  // Callback: type, duration
    var onTick: ((Int) -> Void)? { get set }                          // Callback: remaining seconds
}

enum TimerState {
    case idle
    case running
    case paused
    case completed
}
```

**Behavior**:
- `start()` records session start time in SwiftData
- Timer uses `Date`-based elapsed time (not tick counting)
- Subscribes to `NSWorkspace.willSleepNotification` / `didWakeNotification`
- On wake: recalculates remaining time from wall clock
- `onSessionComplete` triggers gamification and notification flows

---

## GamificationService

Calculates XP, manages levels, evaluates achievements.

```swift
protocol GamificationServiceProtocol {
    var currentXP: Int { get }
    var currentLevel: Int { get }
    var currentLevelTitle: String { get }
    var xpForNextLevel: Int { get }
    
    func calculateXP(
        sessionType: SessionType,
        streakDays: Int,
        level: Int
    ) -> XPResult
    
    func evaluateAchievements(
        totalPomodoros: Int,
        currentStreak: Int,
        dailyPomodoros: Int,
        sessionHour: Int,
        isWeekend: Bool,
        linkedSessions: Int,
        currentLevel: Int
    ) -> [AchievementUnlock]
    
    func levelForXP(_ xp: Int) -> (level: Int, title: String)
}

struct XPResult {
    let baseXP: Int
    let streakMultiplier: Double
    let levelMultiplier: Double
    let dailyGoalBonus: Int
    let totalXP: Int
}

struct AchievementUnlock {
    let achievementId: String
    let title: String
    let xpBonus: Int
}
```

---

## StreakService

Manages daily streak tracking and freeze logic.

```swift
protocol StreakServiceProtocol {
    var currentStreak: Int { get }
    var streakFreezesRemaining: Int { get }
    var dailyGoalMet: Bool { get }
    
    func recordDailyGoalMet()                  // Mark today's goal as achieved
    func checkAndUpdateStreak()                // Called at app launch / midnight
    func useStreakFreeze() -> Bool              // Returns true if freeze was available
    func resetWeeklyFreezes()                  // Called at start of new ISO week
}
```

**Behavior**:
- `checkAndUpdateStreak()` compares `lastStreakDate` with today
- If yesterday's goal was met → streak continues
- If yesterday's goal was NOT met → try auto-freeze, else reset to 0
- Streak freeze resets to 1 at the start of each ISO week

---

## ReminderService

Wraps EventKit for Apple Reminders access.

```swift
protocol ReminderServiceProtocol {
    var isAuthorized: Bool { get }
    
    func requestAccess() async -> Bool
    func fetchReminders() async -> [ReminderItem]
    func searchReminders(query: String) async -> [ReminderItem]
    func createReminder(title: String) async -> ReminderItem?
    func appendFocusTime(
        reminderId: String,
        minutes: Int,
        date: Date
    ) async -> Bool
    func markComplete(reminderId: String) async -> Bool
}

struct ReminderItem: Identifiable {
    let id: String          // calendarItemIdentifier
    let title: String
    let listName: String
    let isCompleted: Bool
}
```

**Behavior**:
- `requestAccess()` calls `EKEventStore.requestFullAccessToReminders()`
- All methods return empty/false when not authorized (graceful degradation)
- `appendFocusTime` appends "FocusBar: {N} min on {date}" to reminder notes

---

## NotificationService

Wraps UNUserNotificationCenter.

```swift
protocol NotificationServiceProtocol {
    var isAuthorized: Bool { get }
    
    func requestPermission() async -> Bool
    func sendSessionComplete(
        sessionType: SessionType,
        nextSessionType: SessionType
    )
    func sendAchievementUnlocked(title: String, xpBonus: Int)
    func sendLevelUp(level: Int, title: String)
    func sendDailyGoalMet(streak: Int)
    func playSound(named: String)
}
```

---

## ExportService

Exports all user data to JSON.

```swift
protocol ExportServiceProtocol {
    func exportAll(
        sessions: [Session],
        achievements: [Achievement],
        dailyStats: [DailyStats]
    ) async throws -> URL
}
```

**Behavior**:
- Presents `NSSavePanel` for file location
- Default filename: `focusbar-export-YYYY-MM-DD.json`
- Encodes all entities + UserDefaults preferences to single JSON file
