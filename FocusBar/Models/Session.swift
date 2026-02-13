import Foundation
import SwiftData

@Model
final class Session {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var duration: Int
    var type: String
    var completed: Bool
    var reminderId: String?
    var reminderTitle: String?
    var xpEarned: Int

    init(
        startTime: Date,
        duration: Int,
        type: SessionType,
        completed: Bool = false,
        reminderId: String? = nil,
        reminderTitle: String? = nil,
        xpEarned: Int = 0
    ) {
        self.id = UUID()
        self.startTime = startTime
        self.duration = duration
        self.type = type.rawValue
        self.completed = completed
        self.reminderId = reminderId
        self.reminderTitle = reminderTitle
        self.xpEarned = xpEarned
    }

    var sessionType: SessionType {
        get { SessionType(rawValue: type) ?? .pomodoro }
        set { type = newValue.rawValue }
    }
}
