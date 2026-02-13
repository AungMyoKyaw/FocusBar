import Foundation
import SwiftData

@Observable
final class StatsViewModel {
    var timeRange: TimeRange = .weekly
    var sessions: [Session] = []
    var dailyStats: [DailyStats] = []

    enum TimeRange: String, CaseIterable {
        case daily = "Today"
        case weekly = "This Week"
        case monthly = "This Month"
    }

    func loadStats(modelContext: ModelContext) {
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
        sessions = (try? modelContext.fetch(sessionDescriptor)) ?? []

        let statsDescriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate { $0.date >= startDate },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        dailyStats = (try? modelContext.fetch(statsDescriptor)) ?? []
    }

    var totalFocusHours: Double {
        let minutes = sessions.filter { $0.type == SessionType.pomodoro.rawValue }
            .reduce(0) { $0 + $1.duration }
        return Double(minutes) / 3600.0
    }

    var totalSessions: Int { sessions.count }

    var averageSessionMinutes: Int {
        let pomodoros = sessions.filter { $0.type == SessionType.pomodoro.rawValue }
        guard !pomodoros.isEmpty else { return 0 }
        return pomodoros.reduce(0) { $0 + $1.duration } / pomodoros.count / 60
    }

    var bestDayPomodoros: Int {
        dailyStats.map(\.pomodorosCompleted).max() ?? 0
    }

    var focusByHour: [(hour: Int, count: Int)] {
        var hourCounts = [Int: Int]()
        for session in sessions where session.type == SessionType.pomodoro.rawValue {
            let hour = Calendar.current.component(.hour, from: session.startTime)
            hourCounts[hour, default: 0] += 1
        }
        return (0..<24).map { (hour: $0, count: hourCounts[$0] ?? 0) }
    }

    var taskBreakdown: [(title: String, minutes: Int)] {
        var breakdown = [String: Int]()
        for session in sessions {
            let title = session.reminderTitle ?? "Unlinked"
            breakdown[title, default: 0] += session.duration / 60
        }
        return breakdown.map { (title: $0.key, minutes: $0.value) }
            .sorted { $0.minutes > $1.minutes }
    }
}
