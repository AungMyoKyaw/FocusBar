import Foundation
import Testing
@testable import FocusBar

@MainActor
struct TimerServiceTests {

    private func makeIsolatedDefaults() -> (UserDefaults, String) {
        let suiteName = "FocusBarTests.Timer.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return (defaults, suiteName)
    }

    @Test func startPauseResumeResetTransitions() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = TimerService(defaults: defaults, debounceInterval: 0)
        #expect(service.state == .idle)
        #expect(service.remainingSeconds == 0)

        service.start(duration: 10)
        #expect(service.state == .running)
        #expect(service.remainingSeconds == 600)

        service.pause()
        #expect(service.state == .paused)

        service.start()
        #expect(service.state == .running)

        service.reset()
        #expect(service.state == .idle)
        #expect(service.remainingSeconds == 0)
    }

    @Test func skipAdvancesWithoutCompletingSession() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = TimerService(defaults: defaults, debounceInterval: 0)
        var completionCalled = false
        service.onSessionComplete = { _, _ in
            completionCalled = true
        }

        service.start(duration: 25)
        service.skip()

        #expect(completionCalled == false)
        #expect(service.state == .idle)
        #expect(service.remainingSeconds == 0)
        #expect(service.currentSessionType == .shortBreak)
        #expect(service.completedPomodorosInCycle == 1)
    }

    @Test func cycleProgressesThroughLongBreakAndResets() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(2, forKey: UserDefaultsKeys.sessionsUntilLongBreak)

        let service = TimerService(defaults: defaults, debounceInterval: 0)
        #expect(service.currentSessionType == .pomodoro)

        service.advanceToNextSession()
        #expect(service.currentSessionType == .shortBreak)
        #expect(service.completedPomodorosInCycle == 1)

        service.advanceToNextSession()
        #expect(service.currentSessionType == .pomodoro)

        service.advanceToNextSession()
        #expect(service.currentSessionType == .longBreak)
        #expect(service.completedPomodorosInCycle == 2)

        service.advanceToNextSession()
        #expect(service.currentSessionType == .pomodoro)
        #expect(service.completedPomodorosInCycle == 0)
    }

    @Test func debouncePreventsRapidDoubleToggle() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = TimerService(defaults: defaults, debounceInterval: 1.0)
        service.start(duration: 15)
        #expect(service.state == .running)

        // Immediate pause within debounce window should be ignored
        service.pause()
        #expect(service.state == .running)
    }
}

@MainActor
struct GamificationServiceTests {
    private let service = GamificationService()

    @Test func calculateXPAppliesMultipliersAndCapsStreak() {
        // Base 25, streak 0 -> 1.0x, level 1 -> 1.05x, no bonus -> round(26.25) = 26
        let basic = service.calculateXP(sessionType: .pomodoro, streakDays: 0, level: 1, dailyGoalJustMet: false)
        #expect(basic.baseXP == 25)
        #expect(basic.streakMultiplier == 1.0)
        #expect(basic.dailyGoalBonus == 0)
        #expect(basic.totalXP == 26)

        // Streak 100 should cap at maxStreakMultiplier (2.0), daily goal adds 50
        let capped = service.calculateXP(sessionType: .pomodoro, streakDays: 100, level: 2, dailyGoalJustMet: true)
        #expect(capped.streakMultiplier == Constants.maxStreakMultiplier)
        #expect(capped.dailyGoalBonus == Constants.dailyGoalBonusXP)
        // 25 * 2.0 * 1.10 = 55 + 50 = 105
        #expect(capped.totalXP == 105)
    }

    @Test func levelProgressionBoundaries() {
        #expect(service.levelForXP(0).level == 1)
        #expect(service.levelForXP(249).level == 1)
        #expect(service.levelForXP(250).level == 2)
        #expect(service.levelForXP(100_000).level == 30)
        #expect(service.xpForNextLevel(currentXP: 0) == 250)
        #expect(service.xpForNextLevel(currentXP: 100_000) == 100_000)
    }

    @Test func evaluateAchievementsUnlocksAndDeduplicates() {
        let unlocks = service.evaluateAchievements(
            totalPomodoros: 5,
            currentStreak: 7,
            dailyPomodoros: 4,
            sessionHour: 6,
            isWeekend: true,
            linkedSessions: 10,
            currentLevel: 5,
            weekendSessions: 20,
            usedStreakFreeze: true,
            alreadyUnlocked: ["first_focus"]
        )
        let ids = Set(unlocks.map(\.achievementId))
        #expect(!ids.contains("first_focus"))
        #expect(ids.contains("dip_your_toes"))
        #expect(ids.contains("week_warrior"))
        #expect(ids.contains("half_day"))
        #expect(ids.contains("early_bird"))
        #expect(ids.contains("weekend_warrior"))
        #expect(ids.contains("task_master"))
        #expect(ids.contains("level_five"))
        #expect(ids.contains("streak_saver"))
    }
}

@MainActor
struct StreakServiceTests {

    private func makeIsolatedDefaults() -> (UserDefaults, String) {
        let suiteName = "FocusBarTests.Streak.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return (defaults, suiteName)
    }

    private func dateString(daysAgo: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return formatter.string(from: date)
    }

    @Test func incrementAndPreserveStreakForTodayAndYesterday() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = StreakService(defaults: defaults)
        service.incrementStreak()
        #expect(service.currentStreak == 1)
        #expect(service.lastStreakDate == dateString(daysAgo: 0))

        service.checkAndUpdateStreak()
        #expect(service.currentStreak == 1)

        service.lastStreakDate = dateString(daysAgo: 1)
        service.checkAndUpdateStreak()
        #expect(service.currentStreak == 1)
    }

    @Test func missedDayConsumesFreezeThenResetsWhenExhausted() {
        let (defaults, suiteName) = makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = StreakService(defaults: defaults)
        service.currentStreak = 4
        service.lastStreakDate = dateString(daysAgo: 2)
        // Ensure weekly freeze reset won't overwrite our test setup
        defaults.set(Calendar.current.component(.weekOfYear, from: Date()), forKey: UserDefaultsKeys.lastFreezeResetWeek)
        service.streakFreezesRemaining = 1

        service.checkAndUpdateStreak()
        #expect(service.currentStreak == 4)
        #expect(service.streakFreezesRemaining == 0)
        #expect(service.hasUsedStreakFreeze == true)

        // Next missed day with 0 freezes resets streak
        service.checkAndUpdateStreak()
        #expect(service.currentStreak == 0)
    }
}

@MainActor
struct ExportServiceTests {

    @Test func encodeExportDataProducesValidJSON() throws {
        let service = ExportService()
        let session = Session(
            startTime: Date(timeIntervalSince1970: 1_700_000_000),
            duration: 1500,
            type: .pomodoro,
            completed: true,
            reminderId: "rem-1",
            reminderTitle: "Ship v1.0.0",
            xpEarned: 26
        )
        let achievement = Achievement(type: "first_focus", unlockedAt: Date(timeIntervalSince1970: 1_700_000_500))
        let stats = DailyStats(date: Date(timeIntervalSince1970: 1_700_000_000))
        stats.pomodorosCompleted = 1
        stats.totalFocusMinutes = 25
        stats.xpEarned = 26

        let data = try service.encodeExportData(sessions: [session], achievements: [achievement], dailyStats: [stats])
        let decoded = try JSONDecoder().decode(ExportData.self, from: data)

        #expect(decoded.sessions.count == 1)
        #expect(decoded.sessions.first?.reminderTitle == "Ship v1.0.0")
        #expect(decoded.sessions.first?.xpEarned == 26)
        #expect(decoded.achievements.count == 1)
        #expect(decoded.achievements.first?.type == "first_focus")
        #expect(decoded.dailyStats.count == 1)
        #expect(decoded.dailyStats.first?.pomodorosCompleted == 1)
    }
}
