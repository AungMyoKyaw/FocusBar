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

        let newLevel = gamificationService.levelForXP(currentXP)
        if newLevel.level > currentLevel {
            currentLevel = newLevel.level
            notificationService.sendLevelUp(level: newLevel.level, title: newLevel.title)
        }

        if dailyGoalJustMet {
            streakService.incrementStreak()
            notificationService.sendDailyGoalMet(streak: streakService.currentStreak)
        }

        updateDailyStats(xpEarned: xpResult.totalXP, sessionType: sessionType, modelContext: modelContext)
    }

    func checkStreakOnLaunch() {
        streakService.checkAndUpdateStreak()
    }

    private func updateDailyStats(xpEarned: Int, sessionType: SessionType, modelContext: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let descriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate { $0.date >= today && $0.date < tomorrow }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            if sessionType == .pomodoro {
                existing.pomodorosCompleted += 1
                existing.totalFocusMinutes += UserDefaults.standard.integer(forKey: UserDefaultsKeys.pomodoroDuration)
            }
            existing.xpEarned += xpEarned
            existing.streakMaintained = streakService.currentStreak > 0
        } else {
            let stats = DailyStats(date: today)
            if sessionType == .pomodoro {
                stats.pomodorosCompleted = 1
                stats.totalFocusMinutes = UserDefaults.standard.integer(forKey: UserDefaultsKeys.pomodoroDuration)
            }
            stats.xpEarned = xpEarned
            stats.streakMaintained = streakService.currentStreak > 0
            modelContext.insert(stats)
        }
        try? modelContext.save()
    }
}
