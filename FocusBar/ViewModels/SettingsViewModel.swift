import Foundation
import SwiftUI
import ServiceManagement

@Observable
final class SettingsViewModel {
    @ObservationIgnored @AppStorage(UserDefaultsKeys.pomodoroDuration) var pomodoroDuration = Constants.defaultPomodoroDuration
    @ObservationIgnored @AppStorage(UserDefaultsKeys.shortBreakDuration) var shortBreakDuration = Constants.defaultShortBreakDuration
    @ObservationIgnored @AppStorage(UserDefaultsKeys.longBreakDuration) var longBreakDuration = Constants.defaultLongBreakDuration
    @ObservationIgnored @AppStorage(UserDefaultsKeys.sessionsUntilLongBreak) var sessionsUntilLongBreak = Constants.defaultSessionsUntilLongBreak
    @ObservationIgnored @AppStorage(UserDefaultsKeys.autoStartNextSession) var autoStartNextSession = false

    @ObservationIgnored @AppStorage(UserDefaultsKeys.menuBarDisplayMode) var menuBarDisplayMode = MenuBarDisplayMode.timerText.rawValue

    @ObservationIgnored @AppStorage(UserDefaultsKeys.soundEnabled) var soundEnabled = false
    @ObservationIgnored @AppStorage(UserDefaultsKeys.bannerEnabled) var bannerEnabled = true

    @ObservationIgnored @AppStorage(UserDefaultsKeys.dailyGoal) var dailyGoal = Constants.defaultDailyGoal

    var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    var launchAtLoginError: String?

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginError = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = SMAppService.mainApp.status == .enabled
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            launchAtLoginError = error.localizedDescription
            LoggingService.logError(.unknown("Launch at login toggle failed: \(error.localizedDescription)"), context: "SettingsViewModel")
        }
    }
}
