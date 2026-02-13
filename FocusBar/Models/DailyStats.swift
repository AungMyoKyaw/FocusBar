import Foundation
import SwiftData

@Model
final class DailyStats {
    var id: UUID
    var date: Date
    var pomodorosCompleted: Int
    var totalFocusMinutes: Int
    var streakMaintained: Bool
    var xpEarned: Int

    init(
        date: Date,
        pomodorosCompleted: Int = 0,
        totalFocusMinutes: Int = 0,
        streakMaintained: Bool = false,
        xpEarned: Int = 0
    ) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.pomodorosCompleted = pomodorosCompleted
        self.totalFocusMinutes = totalFocusMinutes
        self.streakMaintained = streakMaintained
        self.xpEarned = xpEarned
    }
}
