import Foundation
import SwiftData
import AppKit
import UniformTypeIdentifiers

final class ExportService {

    func exportAll(
        sessions: [Session],
        achievements: [Achievement],
        dailyStats: [DailyStats]
    ) async throws -> URL? {
        LoggingService.logInfo("Starting data export (\(sessions.count) sessions, \(achievements.count) achievements, \(dailyStats.count) daily stats)", category: .data)

        let exportData = ExportData(
            exportDate: ISO8601DateFormatter().string(from: Date()),
            sessions: sessions.map { SessionExport(session: $0) },
            achievements: achievements.map { AchievementExport(achievement: $0) },
            dailyStats: dailyStats.map { DailyStatsExport(stats: $0) },
            preferences: exportPreferences()
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data: Data
        do {
            data = try encoder.encode(exportData)
        } catch {
            LoggingService.logError(.exportFailed("Encoding failed: \(error.localizedDescription)"), context: "exportAll")
            throw AppError.exportFailed("Failed to encode export data: \(error.localizedDescription)")
        }

        let panel = NSSavePanel()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        panel.nameFieldStringValue = "focusbar-export-\(formatter.string(from: Date())).json"
        panel.allowedContentTypes = [.json]

        let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSApp.mainWindow ?? NSWindow())
        guard response == .OK, let url = panel.url else {
            LoggingService.logInfo("Export cancelled by user", category: .data)
            return nil
        }

        do {
            try data.write(to: url)
            LoggingService.logInfo("Export saved to \(url.path)", category: .data)
            return url
        } catch {
            LoggingService.logError(.exportFailed("Write failed: \(error.localizedDescription)"), context: "exportAll")
            throw AppError.exportFailed("Failed to write export file: \(error.localizedDescription)")
        }
    }

    private func exportPreferences() -> [String: String] {
        let keys = [
            UserDefaultsKeys.pomodoroDuration,
            UserDefaultsKeys.shortBreakDuration,
            UserDefaultsKeys.longBreakDuration,
            UserDefaultsKeys.sessionsUntilLongBreak,
            UserDefaultsKeys.dailyGoal,
            UserDefaultsKeys.currentXP,
            UserDefaultsKeys.currentLevel,
            UserDefaultsKeys.currentStreak,
        ]
        var prefs = [String: String]()
        for key in keys {
            if let val = UserDefaults.standard.object(forKey: key) {
                prefs[key] = "\(val)"
            }
        }
        return prefs
    }
}

struct ExportData: Codable {
    let exportDate: String
    let sessions: [SessionExport]
    let achievements: [AchievementExport]
    let dailyStats: [DailyStatsExport]
    let preferences: [String: String]
}

struct SessionExport: Codable {
    let id: String
    let startTime: String
    let endTime: String?
    let duration: Int
    let type: String
    let completed: Bool
    let reminderTitle: String?
    let xpEarned: Int

    init(session: Session) {
        let fmt = ISO8601DateFormatter()
        self.id = session.id.uuidString
        self.startTime = fmt.string(from: session.startTime)
        self.endTime = session.endTime.map { fmt.string(from: $0) }
        self.duration = session.duration
        self.type = session.type
        self.completed = session.completed
        self.reminderTitle = session.reminderTitle
        self.xpEarned = session.xpEarned
    }
}

struct AchievementExport: Codable {
    let type: String
    let unlockedAt: String

    init(achievement: Achievement) {
        self.type = achievement.type
        self.unlockedAt = ISO8601DateFormatter().string(from: achievement.unlockedAt)
    }
}

struct DailyStatsExport: Codable {
    let date: String
    let pomodorosCompleted: Int
    let totalFocusMinutes: Int
    let xpEarned: Int

    init(stats: DailyStats) {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        self.date = fmt.string(from: stats.date)
        self.pomodorosCompleted = stats.pomodorosCompleted
        self.totalFocusMinutes = stats.totalFocusMinutes
        self.xpEarned = stats.xpEarned
    }
}
