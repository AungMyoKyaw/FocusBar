import Foundation
import SwiftUI

enum UserDefaultsKeys {
    static let pomodoroDuration = "focusBar.timer.pomodoroDuration"
    static let shortBreakDuration = "focusBar.timer.shortBreakDuration"
    static let longBreakDuration = "focusBar.timer.longBreakDuration"
    static let sessionsUntilLongBreak = "focusBar.timer.sessionsUntilLongBreak"

    static let menuBarDisplayMode = "focusBar.display.menuBarMode"
    static let showIcon = "focusBar.display.showIcon"

    static let soundEnabled = "focusBar.notifications.soundEnabled"
    static let bannerEnabled = "focusBar.notifications.bannerEnabled"
    static let overlayEnabled = "focusBar.notifications.overlayEnabled"
    static let soundFile = "focusBar.notifications.soundFile"

    static let currentXP = "focusBar.gamification.currentXP"
    static let currentLevel = "focusBar.gamification.currentLevel"
    static let currentStreak = "focusBar.gamification.currentStreak"
    static let lastStreakDate = "focusBar.gamification.lastStreakDate"
    static let streakFreezesRemaining = "focusBar.gamification.streakFreezes"
    static let lastFreezeResetWeek = "focusBar.gamification.lastFreezeResetWeek"
    static let dailyGoal = "focusBar.gamification.dailyGoal"

    static let hasCompletedOnboarding = "focusBar.onboarding.hasCompletedOnboarding"
}

enum MenuBarDisplayMode: String, CaseIterable {
    case icon = "icon"
    case timerText = "timerText"
    case progressBar = "progressBar"

    var displayName: String {
        switch self {
        case .icon: return "Icon Only"
        case .timerText: return "Timer Text"
        case .progressBar: return "Progress Bar"
        }
    }
}
