import Foundation

enum Constants {

    static let feedbackURL = "mailto:support@focusbar.app"

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var appBuildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static let defaultPomodoroDuration = 25
    static let defaultShortBreakDuration = 5
    static let defaultLongBreakDuration = 15
    static let defaultSessionsUntilLongBreak = 4
    static let defaultDailyGoal = 4
    static let dailyGoalBonusXP = 50
    static let maxStreakMultiplier = 2.0
    static let streakMultiplierPerDay = 0.05
    static let levelMultiplierPerLevel = 0.05
    static let weeklyStreakFreezes = 1

    struct LevelInfo {
        let level: Int
        let title: String
        let xpRequired: Int
    }

    static let levels: [LevelInfo] = [
        LevelInfo(level: 1, title: "Seedling", xpRequired: 0),
        LevelInfo(level: 2, title: "Sprout", xpRequired: 250),
        LevelInfo(level: 3, title: "Sapling", xpRequired: 600),
        LevelInfo(level: 4, title: "Young Tree", xpRequired: 1_000),
        LevelInfo(level: 5, title: "Growing Tree", xpRequired: 1_500),
        LevelInfo(level: 6, title: "Sturdy Tree", xpRequired: 2_100),
        LevelInfo(level: 7, title: "Tall Tree", xpRequired: 2_800),
        LevelInfo(level: 8, title: "Leafy Tree", xpRequired: 3_600),
        LevelInfo(level: 9, title: "Branching Tree", xpRequired: 4_500),
        LevelInfo(level: 10, title: "Mighty Oak", xpRequired: 5_000),
        LevelInfo(level: 11, title: "Elder Oak", xpRequired: 5_800),
        LevelInfo(level: 12, title: "Wise Oak", xpRequired: 6_800),
        LevelInfo(level: 13, title: "Deep Roots", xpRequired: 8_000),
        LevelInfo(level: 14, title: "Forest Keeper", xpRequired: 9_500),
        LevelInfo(level: 15, title: "Ancient Grove", xpRequired: 12_000),
        LevelInfo(level: 16, title: "Grove Warden", xpRequired: 14_500),
        LevelInfo(level: 17, title: "Woodland Sage", xpRequired: 17_500),
        LevelInfo(level: 18, title: "Nature's Voice", xpRequired: 20_500),
        LevelInfo(level: 19, title: "Elder Spirit", xpRequired: 23_000),
        LevelInfo(level: 20, title: "Forest Guardian", xpRequired: 25_000),
        LevelInfo(level: 21, title: "Timeless Oak", xpRequired: 28_000),
        LevelInfo(level: 22, title: "Eternal Roots", xpRequired: 32_000),
        LevelInfo(level: 23, title: "Spirit Walker", xpRequired: 37_000),
        LevelInfo(level: 24, title: "Ancient Wisdom", xpRequired: 43_000),
        LevelInfo(level: 25, title: "Nature Spirit", xpRequired: 50_000),
        LevelInfo(level: 26, title: "Cosmic Seed", xpRequired: 60_000),
        LevelInfo(level: 27, title: "Stellar Grove", xpRequired: 72_000),
        LevelInfo(level: 28, title: "Celestial Oak", xpRequired: 85_000),
        LevelInfo(level: 29, title: "Infinite Focus", xpRequired: 92_000),
        LevelInfo(level: 30, title: "Focus Master", xpRequired: 100_000),
    ]

    struct AchievementDefinition {
        let id: String
        let title: String
        let description: String
        let category: String
        let xpBonus: Int
    }

    static let achievements: [AchievementDefinition] = [
        AchievementDefinition(id: "first_focus", title: "First Focus", description: "Complete your first Pomodoro", category: "Getting Started", xpBonus: 10),
        AchievementDefinition(id: "dip_your_toes", title: "Dip Your Toes", description: "Complete 5 Pomodoros", category: "Getting Started", xpBonus: 25),
        AchievementDefinition(id: "getting_serious", title: "Getting Serious", description: "Complete 25 Pomodoros", category: "Getting Started", xpBonus: 50),
        AchievementDefinition(id: "level_five", title: "Rising Star", description: "Reach level 5", category: "Getting Started", xpBonus: 75),
        AchievementDefinition(id: "level_ten", title: "Mighty Achiever", description: "Reach level 10", category: "Getting Started", xpBonus: 200),

        AchievementDefinition(id: "week_warrior", title: "Week Warrior", description: "Maintain a 7-day streak", category: "Consistency", xpBonus: 100),
        AchievementDefinition(id: "fortnight_fighter", title: "Fortnight Fighter", description: "Maintain a 14-day streak", category: "Consistency", xpBonus: 200),
        AchievementDefinition(id: "monthly_master", title: "Monthly Master", description: "Maintain a 30-day streak", category: "Consistency", xpBonus: 500),
        AchievementDefinition(id: "streak_saver", title: "Streak Saver", description: "Use your first streak freeze", category: "Consistency", xpBonus: 15),

        AchievementDefinition(id: "century_club", title: "Century Club", description: "Complete 100 Pomodoros", category: "Volume", xpBonus: 150),
        AchievementDefinition(id: "five_hundred_club", title: "Five Hundred Club", description: "Complete 500 Pomodoros", category: "Volume", xpBonus: 500),
        AchievementDefinition(id: "thousand_club", title: "Thousand Club", description: "Complete 1,000 Pomodoros", category: "Volume", xpBonus: 1_000),

        AchievementDefinition(id: "half_day", title: "Half Day", description: "Complete 4 Pomodoros in one day", category: "Daily Intensity", xpBonus: 50),
        AchievementDefinition(id: "marathon", title: "Marathon", description: "Complete 8 Pomodoros in one day", category: "Daily Intensity", xpBonus: 100),
        AchievementDefinition(id: "iron_focus", title: "Iron Focus", description: "Complete 12 Pomodoros in one day", category: "Daily Intensity", xpBonus: 200),

        AchievementDefinition(id: "night_owl", title: "Night Owl", description: "Complete a session between 12-4 AM", category: "Time Based", xpBonus: 25),
        AchievementDefinition(id: "early_bird", title: "Early Bird", description: "Complete a session between 5-7 AM", category: "Time Based", xpBonus: 25),
        AchievementDefinition(id: "weekend_warrior", title: "Weekend Warrior", description: "Complete 20 sessions on weekends", category: "Time Based", xpBonus: 100),

        AchievementDefinition(id: "task_master", title: "Task Master", description: "Link 10 sessions to reminders", category: "Task Mastery", xpBonus: 50),
        AchievementDefinition(id: "project_pro", title: "Project Pro", description: "Complete 50 linked sessions", category: "Task Mastery", xpBonus: 150),
    ]
}
