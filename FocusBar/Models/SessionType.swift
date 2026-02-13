import Foundation

enum SessionType: String, Codable, CaseIterable {
    case pomodoro = "pomodoro"
    case shortBreak = "shortBreak"
    case longBreak = "longBreak"

    var displayName: String {
        switch self {
        case .pomodoro: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    var defaultDurationMinutes: Int {
        switch self {
        case .pomodoro: return 25
        case .shortBreak: return 5
        case .longBreak: return 15
        }
    }

    var baseXP: Int {
        switch self {
        case .pomodoro: return 25
        case .shortBreak: return 5
        case .longBreak: return 15
        }
    }
}
