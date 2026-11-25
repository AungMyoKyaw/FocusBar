import Foundation
import SwiftData

@Observable
final class StatsViewModel {
    var timeRange: TimeRange = .weekly
    var sessions: [Session] = []
    var allSessionsForHeatmap: [Session] = []
    var dailyStats: [DailyStats] = []
    var currentError: AppError?

    enum TimeRange: String, CaseIterable {
        case daily = "Today"
        case weekly = "This Week"
        case monthly = "This Month"
        case yearly = "This Year"
        case allTime = "All Time"
    }

    func loadStats(modelContext: ModelContext) {
        currentError = nil
        let startDate: Date
        let now = Date()
        let cal = Calendar.current

        switch timeRange {
        case .daily:
            startDate = cal.startOfDay(for: now)
        case .weekly:
            startDate = cal.date(byAdding: .day, value: -7, to: now) ?? now
        case .monthly:
            startDate = cal.date(byAdding: .month, value: -1, to: now) ?? now
        case .yearly:
            startDate = cal.date(byAdding: .year, value: -1, to: now) ?? now
        case .allTime:
            startDate = Date.distantPast
        }

        let sessionDescriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.startTime >= startDate && $0.completed == true },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        do {
            sessions = try modelContext.fetch(sessionDescriptor)
        } catch {
            let appError = AppError.dataError("Failed to load sessions: \(error.localizedDescription)")
            LoggingService.logError(appError, context: "StatsViewModel.loadStats")
            currentError = appError
            sessions = []
        }

        let heatmapStart = cal.date(byAdding: .day, value: -112, to: cal.startOfDay(for: now)) ?? now
        let heatmapDescriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.startTime >= heatmapStart && $0.completed == true }
        )
        allSessionsForHeatmap = (try? modelContext.fetch(heatmapDescriptor)) ?? []

        let statsDescriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate { $0.date >= startDate },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            dailyStats = try modelContext.fetch(statsDescriptor)
        } catch {
            let appError = AppError.dataError("Failed to load daily stats: \(error.localizedDescription)")
            LoggingService.logError(appError, context: "StatsViewModel.loadStats")
            currentError = currentError ?? appError
            dailyStats = []
        }
    }

    func deleteSession(_ session: Session, modelContext: ModelContext) {
        modelContext.delete(session)
        do {
            try modelContext.save()
            loadStats(modelContext: modelContext)
        } catch {
            currentError = .dataError("Failed to delete session: \(error.localizedDescription)")
        }
    }

    func addManualSession(
        durationMinutes: Int,
        taskTitle: String,
        tag: String,
        notes: String,
        date: Date,
        modelContext: ModelContext
    ) {
        let clampedMinutes = min(max(durationMinutes, 1), 240)
        let session = Session(
            startTime: date,
            duration: clampedMinutes * 60,
            type: .pomodoro,
            completed: true,
            reminderId: nil,
            reminderTitle: nil,
            xpEarned: 0,
            taskTitle: taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : taskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            tag: tag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : tag.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            overtimeSeconds: 0
        )
        session.endTime = date.addingTimeInterval(TimeInterval(clampedMinutes * 60))
        modelContext.insert(session)
        do {
            try modelContext.save()
            loadStats(modelContext: modelContext)
        } catch {
            currentError = .dataError("Failed to save manual session: \(error.localizedDescription)")
        }
    }

    var completedPomodoros: [Session] {
        sessions.filter { $0.type == SessionType.pomodoro.rawValue }
    }

    var totalFocusHours: Double {
        let seconds = completedPomodoros.reduce(0) { $0 + $1.duration }
        return Double(seconds) / 3600.0
    }

    var totalSessions: Int { completedPomodoros.count }

    var averageSessionMinutes: Int {
        let pomodoros = completedPomodoros
        guard !pomodoros.isEmpty else { return 0 }
        return pomodoros.reduce(0) { $0 + $1.duration } / pomodoros.count / 60
    }

    var bestDayPomodoros: Int {
        dailyStats.map(\.pomodorosCompleted).max() ?? 0
    }

    var focusByHour: [(hour: Int, count: Int)] {
        var hourCounts = [Int: Int]()
        for session in completedPomodoros {
            let hour = Calendar.current.component(.hour, from: session.startTime)
            hourCounts[hour, default: 0] += 1
        }
        return (0..<24).map { (hour: $0, count: hourCounts[$0] ?? 0) }
    }

    var taskBreakdown: [(title: String, minutes: Int)] {
        var breakdown = [String: Int]()
        for session in completedPomodoros {
            let title = session.displayTaskTitle
            breakdown[title, default: 0] += max(1, session.duration / 60)
        }
        return breakdown.map { (title: $0.key, minutes: $0.value) }
            .sorted { $0.minutes > $1.minutes }
    }

    var heatmapDays: [(date: Date, count: Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var countsByDay = [Date: Int]()
        for session in allSessionsForHeatmap where session.type == SessionType.pomodoro.rawValue {
            let day = cal.startOfDay(for: session.startTime)
            countsByDay[day, default: 0] += 1
        }
        return (0..<112).reversed().compactMap { offset -> (date: Date, count: Int)? in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return (date: day, count: countsByDay[day] ?? 0)
        }
    }
}
