import Foundation

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

final class GamificationService {

    func calculateXP(sessionType: SessionType, streakDays: Int, level: Int, dailyGoalJustMet: Bool) -> XPResult {
        let baseXP = sessionType.baseXP
        let streakMult = min(1.0 + Double(streakDays) * Constants.streakMultiplierPerDay, Constants.maxStreakMultiplier)
        let levelMult = 1.0 + Double(level) * Constants.levelMultiplierPerLevel
        let adjustedXP = Double(baseXP) * streakMult * levelMult
        let goalBonus = dailyGoalJustMet ? Constants.dailyGoalBonusXP : 0
        let total = Int(adjustedXP.rounded()) + goalBonus

        return XPResult(
            baseXP: baseXP,
            streakMultiplier: streakMult,
            levelMultiplier: levelMult,
            dailyGoalBonus: goalBonus,
            totalXP: total
        )
    }

    func levelForXP(_ xp: Int) -> (level: Int, title: String) {
        var result = Constants.levels[0]
        for info in Constants.levels {
            if xp >= info.xpRequired {
                result = info
            } else {
                break
            }
        }
        return (result.level, result.title)
    }

    func xpForNextLevel(currentXP: Int) -> Int {
        for info in Constants.levels {
            if info.xpRequired > currentXP {
                return info.xpRequired
            }
        }
        return Constants.levels.last?.xpRequired ?? 0
    }

    func evaluateAchievements(
        totalPomodoros: Int,
        currentStreak: Int,
        dailyPomodoros: Int,
        sessionHour: Int,
        isWeekend: Bool,
        linkedSessions: Int,
        currentLevel: Int,
        weekendSessions: Int,
        usedStreakFreeze: Bool,
        alreadyUnlocked: Set<String>
    ) -> [AchievementUnlock] {
        var unlocks: [AchievementUnlock] = []

        let conditions: [(String, Bool)] = [
            ("first_focus", totalPomodoros >= 1),
            ("dip_your_toes", totalPomodoros >= 5),
            ("getting_serious", totalPomodoros >= 25),
            ("level_five", currentLevel >= 5),
            ("level_ten", currentLevel >= 10),
            ("week_warrior", currentStreak >= 7),
            ("fortnight_fighter", currentStreak >= 14),
            ("monthly_master", currentStreak >= 30),
            ("streak_saver", usedStreakFreeze),
            ("century_club", totalPomodoros >= 100),
            ("five_hundred_club", totalPomodoros >= 500),
            ("thousand_club", totalPomodoros >= 1000),
            ("half_day", dailyPomodoros >= 4),
            ("marathon", dailyPomodoros >= 8),
            ("iron_focus", dailyPomodoros >= 12),
            ("night_owl", sessionHour >= 0 && sessionHour < 4),
            ("early_bird", sessionHour >= 5 && sessionHour < 7),
            ("weekend_warrior", weekendSessions >= 20),
            ("task_master", linkedSessions >= 10),
            ("project_pro", linkedSessions >= 50),
        ]

        for (id, met) in conditions {
            if met && !alreadyUnlocked.contains(id) {
                if let def = Constants.achievements.first(where: { $0.id == id }) {
                    unlocks.append(AchievementUnlock(achievementId: id, title: def.title, xpBonus: def.xpBonus))
                }
            }
        }

        return unlocks
    }
}
