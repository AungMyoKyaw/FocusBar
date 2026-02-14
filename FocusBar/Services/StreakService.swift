import Foundation

final class StreakService {
    private let defaults = UserDefaults.standard

    var currentStreak: Int {
        get { defaults.integer(forKey: UserDefaultsKeys.currentStreak) }
        set { defaults.set(newValue, forKey: UserDefaultsKeys.currentStreak) }
    }

    var streakFreezesRemaining: Int {
        get {
            let val = defaults.integer(forKey: UserDefaultsKeys.streakFreezesRemaining)
            return val > 0 || defaults.object(forKey: UserDefaultsKeys.streakFreezesRemaining) != nil ? val : Constants.weeklyStreakFreezes
        }
        set { defaults.set(newValue, forKey: UserDefaultsKeys.streakFreezesRemaining) }
    }

    var lastStreakDate: String {
        get { defaults.string(forKey: UserDefaultsKeys.lastStreakDate) ?? "" }
        set { defaults.set(newValue, forKey: UserDefaultsKeys.lastStreakDate) }
    }

    var dailyGoal: Int {
        let val = defaults.integer(forKey: UserDefaultsKeys.dailyGoal)
        return val > 0 ? val : Constants.defaultDailyGoal
    }

    func recordDailyGoalMet() {
        let today = todayString()
        lastStreakDate = today
    }

    func checkAndUpdateStreak() {
        resetWeeklyFreezesIfNeeded()

        let today = todayString()
        let yesterday = yesterdayString()

        if lastStreakDate == today {
            return
        }

        if lastStreakDate == yesterday {
            return
        }

        if lastStreakDate.isEmpty {
            return
        }

        if useStreakFreeze() {
            LoggingService.logInfo("Streak freeze auto-applied, streak preserved at \(currentStreak)", category: .gamification)
            return
        }

        LoggingService.logInfo("Streak broken, resetting from \(currentStreak) to 0", category: .gamification)
        currentStreak = 0
    }

    func incrementStreak() {
        currentStreak += 1
        LoggingService.logInfo("Streak incremented to \(currentStreak)", category: .gamification)
        recordDailyGoalMet()
    }

    func useStreakFreeze() -> Bool {
        if streakFreezesRemaining > 0 {
            streakFreezesRemaining -= 1
            LoggingService.logInfo("Streak freeze used, \(streakFreezesRemaining) remaining", category: .gamification)
            return true
        }
        return false
    }

    private func resetWeeklyFreezesIfNeeded() {
        let currentWeek = Calendar.current.component(.weekOfYear, from: Date())
        let lastResetWeek = defaults.integer(forKey: UserDefaultsKeys.lastFreezeResetWeek)
        if currentWeek != lastResetWeek {
            streakFreezesRemaining = Constants.weeklyStreakFreezes
            defaults.set(currentWeek, forKey: UserDefaultsKeys.lastFreezeResetWeek)
        }
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func yesterdayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return formatter.string(from: yesterday)
    }
}
