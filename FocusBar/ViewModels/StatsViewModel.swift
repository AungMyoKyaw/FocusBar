import Foundation
import SwiftData

@Observable
final class StatsViewModel {
    var timeRange: TimeRange = .weekly
    var sessions: [Session] = []
    var dailyStats: [DailyStats] = []
    var currentError: AppError?

    enum TimeRange: String, CaseIterable {
        case daily = "Today"
        case weekly = "This Week"
        case monthly = "This Month"
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
            let title = session.reminderTitle ?? "Unlinked"
            breakdown[title, default: 0] += max(1, session.duration / 60)
        }
        return breakdown.map { (title: $0.key, minutes: $0.value) }
            .sorted { $0.minutes > $1.minutes }
    }
}
