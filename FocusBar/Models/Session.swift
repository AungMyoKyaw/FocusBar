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
    var taskTitle: String? = nil
    var tag: String? = nil
    var notes: String? = nil
    var overtimeSeconds: Int = 0

    init(
        startTime: Date,
        duration: Int,
        type: SessionType,
        completed: Bool = false,
        reminderId: String? = nil,
        reminderTitle: String? = nil,
        xpEarned: Int = 0,
        taskTitle: String? = nil,
        tag: String? = nil,
        notes: String? = nil,
        overtimeSeconds: Int = 0
    ) {
        self.id = UUID()
        self.startTime = startTime
        self.duration = duration
        self.type = type.rawValue
        self.completed = completed
        self.reminderId = reminderId
        self.reminderTitle = reminderTitle
        self.xpEarned = xpEarned
        self.taskTitle = taskTitle
        self.tag = tag
        self.notes = notes
        self.overtimeSeconds = overtimeSeconds
    }

    var sessionType: SessionType {
        get { SessionType(rawValue: type) ?? .pomodoro }
        set { type = newValue.rawValue }
    }

    var displayTaskTitle: String {
        if let taskTitle, !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return taskTitle
        }
        if let reminderTitle, !reminderTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return reminderTitle
        }
        if let tag, !tag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "#\(tag)"
        }
        return "Unlinked"
    }
}
