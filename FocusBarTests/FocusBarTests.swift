import Foundation
import SwiftData
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

@MainActor
struct StatsViewModelTests {

    @Test func loadStatsAggregatesOnlyCompletedPomodorosForTasks() throws {
        let schema = Schema([Session.self, DailyStats.self, Achievement.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let dayStart = Calendar.current.startOfDay(for: Date())
        let focus1 = Session(startTime: dayStart.addingTimeInterval(3600), duration: 1500, type: .pomodoro, completed: true, reminderId: "r1", reminderTitle: "Write tests", xpEarned: 25)
        let focus2 = Session(startTime: dayStart.addingTimeInterval(5400), duration: 1800, type: .pomodoro, completed: true, reminderId: "r1", reminderTitle: "Write tests", xpEarned: 25)
        let shortBreak = Session(startTime: dayStart.addingTimeInterval(7200), duration: 300, type: .shortBreak, completed: true, xpEarned: 5)
        let incomplete = Session(startTime: dayStart.addingTimeInterval(7500), duration: 1500, type: .pomodoro, completed: false, xpEarned: 0)

        let stats = DailyStats(date: dayStart)
        stats.pomodorosCompleted = 2

        context.insert(focus1)
        context.insert(focus2)
        context.insert(shortBreak)
        context.insert(incomplete)
        context.insert(stats)
        try context.save()

        let vm = StatsViewModel()
        vm.timeRange = .daily
        vm.loadStats(modelContext: context)

        #expect(vm.currentError == nil)
        #expect(vm.totalSessions == 2)
        #expect(abs(vm.totalFocusHours - (3300.0 / 3600.0)) < 0.001)
        #expect(vm.averageSessionMinutes == 27)
        #expect(vm.bestDayPomodoros == 2)
        #expect(vm.taskBreakdown.count == 1)
        #expect(vm.taskBreakdown.first?.title == "Write tests")
        #expect(vm.taskBreakdown.first?.minutes == 55)
    }
}

@MainActor
struct TimerViewModelTests {

    @Test func menuBarTitleAndSystemImageReflectStateWithoutEmoji() throws {
        let suiteName = "FocusBarTests.TimerVM.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = TimerService(defaults: defaults, debounceInterval: 0)
        let vm = TimerViewModel(timerService: service)

        #expect(vm.menuBarTitle.isEmpty)
        #expect(vm.menuBarSystemImage == "timer")
        #expect(vm.sessionProgress == 0)

        service.start(duration: 25)
        #expect(vm.menuBarTitle == "25:00")
        #expect(vm.menuBarSystemImage == "timer")
        #expect(vm.sessionProgress >= 0 && vm.sessionProgress <= 1)

        vm.pause()
        #expect(vm.menuBarSystemImage == "pause.circle")
        #expect(vm.menuBarTitle == "25:00")

        vm.skip()
        #expect(vm.menuBarTitle.isEmpty)
        #expect(vm.currentSessionType == .shortBreak)
    }

    @Test func selectSessionTypeUpdatesWhenIdleAndIgnoresWhenRunning() throws {
        let suiteName = "FocusBarTests.SelectType.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = TimerService(defaults: defaults, debounceInterval: 0)
        let vm = TimerViewModel(timerService: service)

        #expect(vm.currentSessionType == .pomodoro)
        vm.selectSessionType(.longBreak)
        #expect(vm.currentSessionType == .longBreak)

        vm.startFocus()
        vm.selectSessionType(.shortBreak)
        #expect(vm.currentSessionType == .longBreak)
    }

    @Test func adjustConfiguredDurationClampsBoundsAndIgnoresWhenRunning() throws {
        let suiteName = "FocusBarTests.AdjustDuration.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let originalFocus = UserDefaults.standard.object(forKey: UserDefaultsKeys.pomodoroDuration)
        let originalShort = UserDefaults.standard.object(forKey: UserDefaultsKeys.shortBreakDuration)
        defer {
            if let originalFocus {
                UserDefaults.standard.set(originalFocus, forKey: UserDefaultsKeys.pomodoroDuration)
            } else {
                UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.pomodoroDuration)
            }
            if let originalShort {
                UserDefaults.standard.set(originalShort, forKey: UserDefaultsKeys.shortBreakDuration)
            } else {
                UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.shortBreakDuration)
            }
        }

        UserDefaults.standard.set(25, forKey: UserDefaultsKeys.pomodoroDuration)
        UserDefaults.standard.set(5, forKey: UserDefaultsKeys.shortBreakDuration)

        let service = TimerService(defaults: defaults, debounceInterval: 0)
        let vm = TimerViewModel(timerService: service)

        vm.adjustConfiguredDuration(by: 5)
        #expect(UserDefaults.standard.integer(forKey: UserDefaultsKeys.pomodoroDuration) == 30)

        vm.adjustConfiguredDuration(by: -100)
        #expect(UserDefaults.standard.integer(forKey: UserDefaultsKeys.pomodoroDuration) == 1)

        vm.adjustConfiguredDuration(by: 200)
        #expect(UserDefaults.standard.integer(forKey: UserDefaultsKeys.pomodoroDuration) == 120)

        vm.selectSessionType(.shortBreak)
        vm.adjustConfiguredDuration(by: 100)
        #expect(UserDefaults.standard.integer(forKey: UserDefaultsKeys.shortBreakDuration) == 60)

        vm.startFocus()
        vm.adjustConfiguredDuration(by: -5)
        #expect(UserDefaults.standard.integer(forKey: UserDefaultsKeys.shortBreakDuration) == 60)
    }
}

@MainActor
struct V2FeatureTests {

    @Test func extendActiveSessionAndTrimIdleSeconds() throws {
        let suiteName = "FocusBarTests.ExtendTrim.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = TimerService(defaults: defaults, debounceInterval: 0)
        service.start(duration: 25)
        #expect(service.remainingSeconds == 1500)

        service.extendActiveSession(by: 5)
        #expect(service.totalDurationSeconds == 1800)
        #expect(service.remainingSeconds >= 1798)

        service.pause()
        let pausedBeforeTrim = service.remainingSeconds
        service.trimElapsedSeconds(120)
        #expect(service.remainingSeconds == min(service.totalDurationSeconds, pausedBeforeTrim + 120))
    }

    @Test func overtimeModeCompletesAndFiresCallback() throws {
        let suiteName = "FocusBarTests.Overtime.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: UserDefaultsKeys.overtimeEnabled)

        let service = TimerService(defaults: defaults, debounceInterval: 0)
        var completedDuration: Int?
        service.onSessionComplete = { _, duration in
            completedDuration = duration
        }

        service.start(duration: 1)
        service.isOvertime = true
        service.overtimeSeconds = 95
        service.completeOvertimeSession()

        #expect(service.state == .idle)
        #expect(service.isOvertime == false)
        #expect(completedDuration == 155)
    }

    @Test func exportCSVAndImportJSONDeduplicates() throws {
        let schema = Schema([Session.self, DailyStats.self, Achievement.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let session = Session(
            startTime: Date(),
            duration: 1500,
            type: .pomodoro,
            completed: true,
            xpEarned: 30,
            taskTitle: "Build v2.0",
            tag: "Coding",
            notes: "Shipped features",
            overtimeSeconds: 45
        )
        context.insert(session)
        try context.save()

        let service = ExportService()
        let csv = service.encodeCSV(sessions: [session])
        #expect(csv.contains("Build v2.0"))
        #expect(csv.contains("Coding"))
        #expect(csv.contains("45"))

        let json = try service.encodeExportData(sessions: [session], achievements: [], dailyStats: [])
        let decoded = try service.decodeExportData(json)
        let firstSummary = try service.applyImport(decoded, modelContext: context)
        #expect(firstSummary.sessionsImported == 0)

        let container2 = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let secondSummary = try service.applyImport(decoded, modelContext: container2.mainContext)
        #expect(secondSummary.sessionsImported == 1)
    }

    @Test func statsViewModelManualSessionHeatmapAndAllTime() throws {
        let schema = Schema([Session.self, DailyStats.self, Achievement.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let vm = StatsViewModel()
        vm.timeRange = .allTime
        vm.addManualSession(
            durationMinutes: 45,
            taskTitle: "Architecture",
            tag: "Design",
            notes: "Offline whiteboard",
            date: Date(),
            modelContext: context
        )

        #expect(vm.totalSessions == 1)
        #expect(vm.taskBreakdown.first?.title == "Architecture")
        #expect(vm.taskBreakdown.first?.minutes == 45)
        #expect(vm.heatmapDays.count == 112)
        #expect(vm.heatmapDays.last?.count == 1)

        if let saved = vm.sessions.first {
            vm.deleteSession(saved, modelContext: context)
        }
        #expect(vm.totalSessions == 0)
    }

    @Test func updateCheckSemverComparison() {
        #expect(UpdateCheckService.isVersion("1.3.0", newerThan: "1.2.0") == true)
        #expect(UpdateCheckService.isVersion("v2.0.0", newerThan: "1.9.9") == true)
        #expect(UpdateCheckService.isVersion("1.2.0", newerThan: "1.2.0") == false)
        #expect(UpdateCheckService.isVersion("1.1.9", newerThan: "1.2.0") == false)
    }

    @Test func customPresetsRoundTrip() throws {
        let suiteName = "FocusBarTests.Presets.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let custom = [TimerPreset(name: "Deep 60/15", focusMinutes: 60, shortBreakMinutes: 15, longBreakMinutes: 30)]
        TimerPreset.saveCustomPresets(custom, to: defaults)
        let loaded = TimerPreset.loadCustomPresets(from: defaults)
        #expect(loaded == custom)
    }

    @Test func floatingWidgetSizeCyclingAndLockState() throws {
        let suiteName = "FocusBarTests.FloatingWidget.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(FloatingWidgetSize.micro.dimensions == CGSize(width: 56, height: 56))
        #expect(FloatingWidgetSize.compact.dimensions == CGSize(width: 224, height: 54))
        #expect(FloatingWidgetSize.expanded.dimensions == CGSize(width: 176, height: 204))

        let controller = FloatingTimerPanelController(defaults: defaults)
        #expect(controller.size == .compact)
        #expect(controller.isLocked == false)

        controller.cycleSize()
        #expect(controller.size == .expanded)
        #expect(defaults.string(forKey: UserDefaultsKeys.floatingWidgetSize) == FloatingWidgetSize.expanded.rawValue)

        controller.cycleSize()
        #expect(controller.size == .micro)

        controller.setLocked(true)
        #expect(controller.isLocked == true)
        #expect(defaults.bool(forKey: UserDefaultsKeys.floatingWidgetLocked) == true)
    }
}

