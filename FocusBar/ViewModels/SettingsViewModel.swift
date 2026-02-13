import Foundation
import SwiftUI

@Observable
final class SettingsViewModel {
    @ObservationIgnored @AppStorage(UserDefaultsKeys.pomodoroDuration) var pomodoroDuration = Constants.defaultPomodoroDuration
    @ObservationIgnored @AppStorage(UserDefaultsKeys.shortBreakDuration) var shortBreakDuration = Constants.defaultShortBreakDuration
    @ObservationIgnored @AppStorage(UserDefaultsKeys.longBreakDuration) var longBreakDuration = Constants.defaultLongBreakDuration
    @ObservationIgnored @AppStorage(UserDefaultsKeys.sessionsUntilLongBreak) var sessionsUntilLongBreak = Constants.defaultSessionsUntilLongBreak

    @ObservationIgnored @AppStorage(UserDefaultsKeys.menuBarDisplayMode) var menuBarDisplayMode = "timerText"

    @ObservationIgnored @AppStorage(UserDefaultsKeys.soundEnabled) var soundEnabled = false
    @ObservationIgnored @AppStorage(UserDefaultsKeys.bannerEnabled) var bannerEnabled = true
    @ObservationIgnored @AppStorage(UserDefaultsKeys.overlayEnabled) var overlayEnabled = false

    @ObservationIgnored @AppStorage(UserDefaultsKeys.dailyGoal) var dailyGoal = Constants.defaultDailyGoal
}
