import Foundation
import SwiftUI

enum UserDefaultsKeys {
    static let pomodoroDuration = "focusBar.timer.pomodoroDuration"
    static let shortBreakDuration = "focusBar.timer.shortBreakDuration"
    static let longBreakDuration = "focusBar.timer.longBreakDuration"
    static let sessionsUntilLongBreak = "focusBar.timer.sessionsUntilLongBreak"
    static let autoStartNextSession = "focusBar.timer.autoStartNextSession"
    static let autoStartBreaks = "focusBar.timer.autoStartBreaks"
    static let autoStartFocus = "focusBar.timer.autoStartFocus"
    static let overtimeEnabled = "focusBar.timer.overtimeEnabled"
    static let breakOverlayEnabled = "focusBar.timer.breakOverlayEnabled"
    static let customPresetsData = "focusBar.timer.customPresetsData"

    static let quickTaskTitle = "focusBar.session.quickTaskTitle"
    static let quickTaskTag = "focusBar.session.quickTaskTag"

    static let menuBarDisplayMode = "focusBar.display.menuBarMode"
    static let showEndTimeInMenuBar = "focusBar.display.showEndTime"

    static let floatingWidgetSize = "focusBar.floating.size"
    static let floatingWidgetOriginX = "focusBar.floating.originX"
    static let floatingWidgetOriginY = "focusBar.floating.originY"
    static let floatingWidgetLocked = "focusBar.floating.locked"

    static let soundEnabled = "focusBar.notifications.soundEnabled"
    static let bannerEnabled = "focusBar.notifications.bannerEnabled"
    static let focusEndSound = "focusBar.audio.focusEndSound"
    static let breakEndSound = "focusBar.audio.breakEndSound"
    static let soundVolume = "focusBar.audio.soundVolume"
    static let ambientSoundMode = "focusBar.audio.ambientSoundMode"
    static let ambientVolume = "focusBar.audio.ambientVolume"

    static let globalHotkeysEnabled = "focusBar.integrations.globalHotkeysEnabled"
    static let calendarSyncEnabled = "focusBar.integrations.calendarSyncEnabled"
    static let calendarName = "focusBar.integrations.calendarName"
    static let idleDetectionEnabled = "focusBar.integrations.idleDetectionEnabled"
    static let idleThresholdMinutes = "focusBar.integrations.idleThresholdMinutes"
    static let distractionGuardEnabled = "focusBar.integrations.distractionGuardEnabled"
    static let blockedBundleIDs = "focusBar.integrations.blockedBundleIDs"

    static let currentXP = "focusBar.gamification.currentXP"
    static let currentLevel = "focusBar.gamification.currentLevel"
    static let currentStreak = "focusBar.gamification.currentStreak"
    static let lastStreakDate = "focusBar.gamification.lastStreakDate"
    static let streakFreezesRemaining = "focusBar.gamification.streakFreezes"
    static let lastFreezeResetWeek = "focusBar.gamification.lastFreezeResetWeek"
    static let hasUsedStreakFreeze = "focusBar.gamification.hasUsedStreakFreeze"
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

enum ChimeSound: String, CaseIterable, Codable {
    case systemDefault
    case glass
    case ping
    case hero
    case submarine
    case tink
    case purr
    case none

    var displayName: String {
        switch self {
        case .systemDefault: return "System Default"
        case .glass: return "Glass"
        case .ping: return "Ping"
        case .hero: return "Hero"
        case .submarine: return "Submarine"
        case .tink: return "Tink"
        case .purr: return "Purr"
        case .none: return "Silent"
        }
    }

    var systemSoundName: String? {
        switch self {
        case .systemDefault: return "Glass"
        case .glass: return "Glass"
        case .ping: return "Ping"
        case .hero: return "Hero"
        case .submarine: return "Submarine"
        case .tink: return "Tink"
        case .purr: return "Purr"
        case .none: return nil
        }
    }
}

enum AmbientSoundMode: String, CaseIterable, Codable {
    case off
    case brownNoise
    case rain
    case swissTick

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .brownNoise: return "Brown Noise"
        case .rain: return "Soft Rain"
        case .swissTick: return "Swiss Tick"
        }
    }

    var symbolName: String {
        switch self {
        case .off: return "speaker.slash"
        case .brownNoise: return "waveform"
        case .rain: return "cloud.rain"
        case .swissTick: return "metronome"
        }
    }
}

struct TimerPreset: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var focusMinutes: Int
    var shortBreakMinutes: Int
    var longBreakMinutes: Int

    init(
        id: UUID = UUID(),
        name: String,
        focusMinutes: Int,
        shortBreakMinutes: Int,
        longBreakMinutes: Int = 15
    ) {
        self.id = id
        self.name = name
        self.focusMinutes = focusMinutes
        self.shortBreakMinutes = shortBreakMinutes
        self.longBreakMinutes = longBreakMinutes
    }

    static let builtInDefaults: [TimerPreset] = [
        TimerPreset(name: "Classic 25/5", focusMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15),
        TimerPreset(name: "Deep 50/10", focusMinutes: 50, shortBreakMinutes: 10, longBreakMinutes: 20),
        TimerPreset(name: "Sprint 15/3", focusMinutes: 15, shortBreakMinutes: 3, longBreakMinutes: 10),
        TimerPreset(name: "Ultradian 90/20", focusMinutes: 90, shortBreakMinutes: 20, longBreakMinutes: 30),
    ]

    static func loadCustomPresets(from defaults: UserDefaults = .standard) -> [TimerPreset] {
        guard let data = defaults.data(forKey: UserDefaultsKeys.customPresetsData) else { return [] }
        return (try? JSONDecoder().decode([TimerPreset].self, from: data)) ?? []
    }

    static func saveCustomPresets(_ presets: [TimerPreset], to defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(presets) {
            defaults.set(data, forKey: UserDefaultsKeys.customPresetsData)
        }
    }
}

enum FloatingWidgetSize: String, CaseIterable, Codable {
    case micro
    case compact
    case expanded

    var displayName: String {
        switch self {
        case .micro: return "Micro (Ring Only)"
        case .compact: return "Compact (Pill)"
        case .expanded: return "Expanded (Dial)"
        }
    }

    var dimensions: CGSize {
        switch self {
        case .micro: return CGSize(width: 56, height: 56)
        case .compact: return CGSize(width: 224, height: 54)
        case .expanded: return CGSize(width: 176, height: 204)
        }
    }
}
