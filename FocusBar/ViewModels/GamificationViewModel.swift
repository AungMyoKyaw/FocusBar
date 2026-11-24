import Foundation
import SwiftUI
import SwiftData

@Observable
final class GamificationViewModel {
    let gamificationService = GamificationService()
    let streakService = StreakService()

    @ObservationIgnored @AppStorage(UserDefaultsKeys.currentXP) var currentXP = 0
    @ObservationIgnored @AppStorage(UserDefaultsKeys.currentLevel) var currentLevel = 1

    var levelTitle: String {
        gamificationService.levelForXP(currentXP).title
    }

    var xpForNextLevel: Int {
        gamificationService.xpForNextLevel(currentXP: currentXP)
    }

    var xpProgress: Double {
        let currentLevelXP = Constants.levels.last(where: { $0.xpRequired <= currentXP })?.xpRequired ?? 0
        let nextLevelXP = xpForNextLevel
        guard nextLevelXP > currentLevelXP else { return 1.0 }
        return Double(currentXP - currentLevelXP) / Double(nextLevelXP - currentLevelXP)
    }

    var currentStreak: Int {
        streakService.currentStreak
    }

    func processSessionComplete(
        sessionType: SessionType,
        durationSeconds: Int,
        dailyPomodoros: Int,
        modelContext: ModelContext,
        notificationService: NotificationService
    ) {
        let dailyGoal = streakService.dailyGoal
        let dailyGoalJustMet = sessionType == .pomodoro && dailyPomodoros == dailyGoal

        let xpResult = gamificationService.calculateXP(
            sessionType: sessionType,
            streakDays: streakService.currentStreak,
            level: currentLevel,
            dailyGoalJustMet: dailyGoalJustMet
        )

        currentXP += xpResult.totalXP

        if dailyGoalJustMet {
            streakService.incrementStreak()
            notificationService.sendDailyGoalMet(streak: streakService.currentStreak)
        }

        evaluateAndUnlockAchievements(
            dailyPomodoros: dailyPomodoros,
            modelContext: modelContext,
            notificationService: notificationService
        )

        let newLevel = gamificationService.levelForXP(currentXP)
        if newLevel.level > currentLevel {
            currentLevel = newLevel.level
            notificationService.sendLevelUp(level: newLevel.level, title: newLevel.title)
        }

        updateDailyStats(
            xpEarned: xpResult.totalXP,
            sessionType: sessionType,
            durationSeconds: durationSeconds,
            modelContext: modelContext
        )
    }

    func checkStreakOnLaunch() {
        streakService.checkAndUpdateStreak()
    }

    private func evaluateAndUnlockAchievements(
        dailyPomodoros: Int,
        modelContext: ModelContext,
        notificationService: NotificationService
    ) {
        let pomodoroType = SessionType.pomodoro.rawValue
        let sessionDescriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.completed == true && $0.type == pomodoroType }
        )
        let completedPomodoros = (try? modelContext.fetch(sessionDescriptor)) ?? []

        let achievementDescriptor = FetchDescriptor<Achievement>()
        let existingAchievements = (try? modelContext.fetch(achievementDescriptor)) ?? []
        let alreadyUnlocked = Set(existingAchievements.map(\.type))

        let calendar = Calendar.current
        let now = Date()
        let sessionHour = calendar.component(.hour, from: now)
        let isWeekend = calendar.isDateInWeekend(now)
        let weekendSessions = completedPomodoros.filter { calendar.isDateInWeekend($0.startTime) }.count
        let linkedSessions = completedPomodoros.filter { $0.reminderId != nil }.count

        let unlocks = gamificationService.evaluateAchievements(
            totalPomodoros: completedPomodoros.count,
            currentStreak: streakService.currentStreak,
            dailyPomodoros: dailyPomodoros,
            sessionHour: sessionHour,
            isWeekend: isWeekend,
            linkedSessions: linkedSessions,
            currentLevel: currentLevel,
            weekendSessions: weekendSessions,
            usedStreakFreeze: streakService.hasUsedStreakFreeze,
            alreadyUnlocked: alreadyUnlocked
        )

        for unlock in unlocks {
            let achievement = Achievement(type: unlock.achievementId)
            modelContext.insert(achievement)
            currentXP += unlock.xpBonus
            notificationService.sendAchievementUnlocked(title: unlock.title, xpBonus: unlock.xpBonus)
        }
    }

    private func updateDailyStats(
        xpEarned: Int,
        sessionType: SessionType,
        durationSeconds: Int,
        modelContext: ModelContext
    ) {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let focusMinutes = max(1, durationSeconds / 60)

        let descriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate { $0.date >= today && $0.date < tomorrow }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            if sessionType == .pomodoro {
                existing.pomodorosCompleted += 1
                existing.totalFocusMinutes += focusMinutes
            }
            existing.xpEarned += xpEarned
            existing.streakMaintained = streakService.currentStreak > 0
        } else {
            let stats = DailyStats(date: today)
            if sessionType == .pomodoro {
                stats.pomodorosCompleted = 1
                stats.totalFocusMinutes = focusMinutes
            }
            stats.xpEarned = xpEarned
            stats.streakMaintained = streakService.currentStreak > 0
            modelContext.insert(stats)
        }
        try? modelContext.save()
    }
}
