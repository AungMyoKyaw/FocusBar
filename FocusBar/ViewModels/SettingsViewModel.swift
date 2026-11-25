import Foundation
import SwiftUI
import ServiceManagement

@Observable
final class SettingsViewModel {
    @ObservationIgnored @AppStorage(UserDefaultsKeys.pomodoroDuration) var pomodoroDuration = Constants.defaultPomodoroDuration
    @ObservationIgnored @AppStorage(UserDefaultsKeys.shortBreakDuration) var shortBreakDuration = Constants.defaultShortBreakDuration
    @ObservationIgnored @AppStorage(UserDefaultsKeys.longBreakDuration) var longBreakDuration = Constants.defaultLongBreakDuration
    @ObservationIgnored @AppStorage(UserDefaultsKeys.sessionsUntilLongBreak) var sessionsUntilLongBreak = Constants.defaultSessionsUntilLongBreak
    @ObservationIgnored @AppStorage(UserDefaultsKeys.autoStartBreaks) var autoStartBreaks = false
    @ObservationIgnored @AppStorage(UserDefaultsKeys.autoStartFocus) var autoStartFocus = false
    @ObservationIgnored @AppStorage(UserDefaultsKeys.overtimeEnabled) var overtimeEnabled = false
    @ObservationIgnored @AppStorage(UserDefaultsKeys.breakOverlayEnabled) var breakOverlayEnabled = false

    @ObservationIgnored @AppStorage(UserDefaultsKeys.menuBarDisplayMode) var menuBarDisplayMode = MenuBarDisplayMode.timerText.rawValue
    @ObservationIgnored @AppStorage(UserDefaultsKeys.showEndTimeInMenuBar) var showEndTimeInMenuBar = false
    @ObservationIgnored @AppStorage(UserDefaultsKeys.floatingWidgetSize) var floatingWidgetSize = FloatingWidgetSize.compact.rawValue

    @ObservationIgnored @AppStorage(UserDefaultsKeys.soundEnabled) var soundEnabled = true
    @ObservationIgnored @AppStorage(UserDefaultsKeys.bannerEnabled) var bannerEnabled = true
    @ObservationIgnored @AppStorage(UserDefaultsKeys.focusEndSound) var focusEndSound = ChimeSound.glass.rawValue
    @ObservationIgnored @AppStorage(UserDefaultsKeys.breakEndSound) var breakEndSound = ChimeSound.ping.rawValue
    @ObservationIgnored @AppStorage(UserDefaultsKeys.soundVolume) var soundVolume = 0.75
    @ObservationIgnored @AppStorage(UserDefaultsKeys.ambientSoundMode) var ambientSoundMode = AmbientSoundMode.off.rawValue
    @ObservationIgnored @AppStorage(UserDefaultsKeys.ambientVolume) var ambientVolume = 0.35

    @ObservationIgnored @AppStorage(UserDefaultsKeys.globalHotkeysEnabled) var globalHotkeysEnabled = true
    @ObservationIgnored @AppStorage(UserDefaultsKeys.calendarSyncEnabled) var calendarSyncEnabled = false
    @ObservationIgnored @AppStorage(UserDefaultsKeys.calendarName) var calendarName = Constants.defaultCalendarName
    @ObservationIgnored @AppStorage(UserDefaultsKeys.idleDetectionEnabled) var idleDetectionEnabled = false
    @ObservationIgnored @AppStorage(UserDefaultsKeys.idleThresholdMinutes) var idleThresholdMinutes = Constants.defaultIdleThresholdMinutes
    @ObservationIgnored @AppStorage(UserDefaultsKeys.distractionGuardEnabled) var distractionGuardEnabled = false
    @ObservationIgnored @AppStorage(UserDefaultsKeys.blockedBundleIDs) var blockedBundleIDs = ""

    @ObservationIgnored @AppStorage(UserDefaultsKeys.dailyGoal) var dailyGoal = Constants.defaultDailyGoal

    var customPresets: [TimerPreset] = TimerPreset.loadCustomPresets()
    var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    var launchAtLoginError: String?

    var isCheckingUpdates = false
    var updateStatus: UpdateCheckResult?

    private let updateService = UpdateCheckService()

    func applyPreset(_ preset: TimerPreset) {
        pomodoroDuration = preset.focusMinutes
        shortBreakDuration = preset.shortBreakMinutes
        longBreakDuration = preset.longBreakMinutes
    }

    func saveCurrentAsPreset(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let preset = TimerPreset(
            name: trimmed,
            focusMinutes: pomodoroDuration,
            shortBreakMinutes: shortBreakDuration,
            longBreakMinutes: longBreakDuration
        )
        customPresets.append(preset)
        TimerPreset.saveCustomPresets(customPresets)
    }

    func deleteCustomPreset(_ preset: TimerPreset) {
        customPresets.removeAll { $0.id == preset.id }
        TimerPreset.saveCustomPresets(customPresets)
    }

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

    func checkForUpdates() async {
        isCheckingUpdates = true
        let result = await updateService.checkForUpdates()
        await MainActor.run {
            updateStatus = result
            isCheckingUpdates = false
        }
    }
}
