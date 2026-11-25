import Foundation
import SwiftData
import AppKit
import UniformTypeIdentifiers

struct ImportSummary: Equatable {
    let sessionsImported: Int
    let achievementsImported: Int
    let dailyStatsImported: Int
}

final class ExportService {

    func encodeExportData(
        sessions: [Session],
        achievements: [Achievement],
        dailyStats: [DailyStats]
    ) throws -> Data {
        let exportData = ExportData(
            exportDate: ISO8601DateFormatter().string(from: Date()),
            sessions: sessions.map { SessionExport(session: $0) },
            achievements: achievements.map { AchievementExport(achievement: $0) },
            dailyStats: dailyStats.map { DailyStatsExport(stats: $0) },
            preferences: exportPreferences()
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            return try encoder.encode(exportData)
        } catch {
            LoggingService.logError(.exportFailed("Encoding failed: \(error.localizedDescription)"), context: "exportAll")
            throw AppError.exportFailed("Failed to encode export data: \(error.localizedDescription)")
        }
    }

    func decodeExportData(_ data: Data) throws -> ExportData {
        do {
            return try JSONDecoder().decode(ExportData.self, from: data)
        } catch {
            throw AppError.dataError("Invalid FocusBar backup file: \(error.localizedDescription)")
        }
    }

    func encodeCSV(sessions: [Session]) -> String {
        var lines = ["id,start_time,end_time,duration_seconds,overtime_seconds,type,completed,task_title,tag,reminder_title,notes,xp_earned"]
        let fmt = ISO8601DateFormatter()
        for session in sessions {
            let fields: [String] = [
                session.id.uuidString,
                fmt.string(from: session.startTime),
                session.endTime.map { fmt.string(from: $0) } ?? "",
                "\(session.duration)",
                "\(session.overtimeSeconds)",
                session.type,
                session.completed ? "true" : "false",
                csvEscape(session.taskTitle ?? ""),
                csvEscape(session.tag ?? ""),
                csvEscape(session.reminderTitle ?? ""),
                csvEscape(session.notes ?? ""),
                "\(session.xpEarned)"
            ]
            lines.append(fields.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    func exportAll(
        sessions: [Session],
        achievements: [Achievement],
        dailyStats: [DailyStats]
    ) async throws -> URL? {
        LoggingService.logInfo("Starting data export (\(sessions.count) sessions, \(achievements.count) achievements, \(dailyStats.count) daily stats)", category: .data)

        let data = try encodeExportData(sessions: sessions, achievements: achievements, dailyStats: dailyStats)

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

    func exportCSV(sessions: [Session]) async throws -> URL? {
        let csv = encodeCSV(sessions: sessions)
        guard let data = csv.data(using: .utf8) else {
            throw AppError.exportFailed("Failed to encode CSV UTF-8 data")
        }

        let panel = NSSavePanel()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        panel.nameFieldStringValue = "focusbar-sessions-\(formatter.string(from: Date())).csv"
        panel.allowedContentTypes = [.commaSeparatedText]

        let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSApp.mainWindow ?? NSWindow())
        guard response == .OK, let url = panel.url else { return nil }

        do {
            try data.write(to: url)
            return url
        } catch {
            throw AppError.exportFailed("Failed to write CSV file: \(error.localizedDescription)")
        }
    }

    func importFromJSON(modelContext: ModelContext) async throws -> ImportSummary? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false

        let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSApp.mainWindow ?? NSWindow())
        guard response == .OK, let url = panel.url else { return nil }

        let data = try Data(contentsOf: url)
        let exportData = try decodeExportData(data)
        return try applyImport(exportData, modelContext: modelContext)
    }

    func applyImport(_ exportData: ExportData, modelContext: ModelContext) throws -> ImportSummary {
        let iso = ISO8601DateFormatter()
        let dayFmt = DateFormatter()
        dayFmt.dateFormat = "yyyy-MM-dd"

        let existingSessions = try modelContext.fetch(FetchDescriptor<Session>())
        let existingIDs = Set(existingSessions.map(\.id))

        let existingAchievements = try modelContext.fetch(FetchDescriptor<Achievement>())
        let existingAchievementTypes = Set(existingAchievements.map(\.type))

        let existingStats = try modelContext.fetch(FetchDescriptor<DailyStats>())
        let existingStatDays = Set(existingStats.map { dayFmt.string(from: $0.date) })

        var sessionsAdded = 0
        for item in exportData.sessions {
            let parsedID = UUID(uuidString: item.id) ?? UUID()
            guard !existingIDs.contains(parsedID) else { continue }
            let start = iso.date(from: item.startTime) ?? Date()
            let sessionType = SessionType(rawValue: item.type) ?? .pomodoro
            let session = Session(
                startTime: start,
                duration: item.duration,
                type: sessionType,
                completed: item.completed,
                reminderId: nil,
                reminderTitle: item.reminderTitle,
                xpEarned: item.xpEarned,
                taskTitle: item.taskTitle,
                tag: item.tag,
                notes: item.notes,
                overtimeSeconds: item.overtimeSeconds ?? 0
            )
            session.id = parsedID
            session.endTime = item.endTime.flatMap { iso.date(from: $0) }
            modelContext.insert(session)
            sessionsAdded += 1
        }

        var achievementsAdded = 0
        for item in exportData.achievements {
            guard !existingAchievementTypes.contains(item.type) else { continue }
            let unlocked = iso.date(from: item.unlockedAt) ?? Date()
            let achievement = Achievement(type: item.type, unlockedAt: unlocked)
            modelContext.insert(achievement)
            achievementsAdded += 1
        }

        var statsAdded = 0
        for item in exportData.dailyStats {
            guard !existingStatDays.contains(item.date) else { continue }
            let date = dayFmt.date(from: item.date) ?? Date()
            let stats = DailyStats(
                date: date,
                pomodorosCompleted: item.pomodorosCompleted,
                totalFocusMinutes: item.totalFocusMinutes,
                xpEarned: item.xpEarned
            )
            modelContext.insert(stats)
            statsAdded += 1
        }

        try modelContext.save()

        let intKeys = [
            UserDefaultsKeys.pomodoroDuration,
            UserDefaultsKeys.shortBreakDuration,
            UserDefaultsKeys.longBreakDuration,
            UserDefaultsKeys.sessionsUntilLongBreak,
            UserDefaultsKeys.dailyGoal,
            UserDefaultsKeys.currentXP,
            UserDefaultsKeys.currentLevel,
            UserDefaultsKeys.currentStreak,
        ]
        for key in intKeys {
            if let str = exportData.preferences[key], let val = Int(str) {
                UserDefaults.standard.set(val, forKey: key)
            }
        }

        return ImportSummary(
            sessionsImported: sessionsAdded,
            achievementsImported: achievementsAdded,
            dailyStatsImported: statsAdded
        )
    }

    func resetAllData(modelContext: ModelContext) throws {
        try modelContext.delete(model: Session.self)
        try modelContext.delete(model: Achievement.self)
        try modelContext.delete(model: DailyStats.self)
        try modelContext.save()

        let resetKeys = [
            UserDefaultsKeys.currentXP,
            UserDefaultsKeys.currentLevel,
            UserDefaultsKeys.currentStreak,
            UserDefaultsKeys.lastStreakDate,
            UserDefaultsKeys.streakFreezesRemaining,
            UserDefaultsKeys.lastFreezeResetWeek,
            UserDefaultsKeys.hasUsedStreakFreeze,
        ]
        for key in resetKeys {
            UserDefaults.standard.removeObject(forKey: key)
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
    let taskTitle: String?
    let tag: String?
    let notes: String?
    let overtimeSeconds: Int?

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
        self.taskTitle = session.taskTitle
        self.tag = session.tag
        self.notes = session.notes
        self.overtimeSeconds = session.overtimeSeconds
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
