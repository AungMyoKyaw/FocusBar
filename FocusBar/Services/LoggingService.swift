import Foundation
import OSLog

enum LogCategory: String {
    case timer
    case gamification
    case reminders
    case data
    case ui
    case permissions
}

enum LoggingService {
    private static let subsystem = "com.aungmyokyaw.FocusBar"

    private static let loggers: [LogCategory: Logger] = {
        var dict = [LogCategory: Logger]()
        for category in [LogCategory.timer, .gamification, .reminders, .data, .ui, .permissions] {
            dict[category] = Logger(subsystem: subsystem, category: category.rawValue)
        }
        return dict
    }()

    static func logger(for category: LogCategory) -> Logger {
        loggers[category]!
    }

    static func logError(_ error: AppError, context: String? = nil) {
        let category: LogCategory = switch error {
        case .dataError: .data
        case .permissionDenied: .permissions
        case .exportFailed: .data
        case .unknown: .ui
        }
        let logger = self.logger(for: category)
        if let context {
            logger.error("\(context): \(error.debugDescription)")
        } else {
            logger.error("\(error.debugDescription)")
        }
    }

    static func logInfo(_ message: String, category: LogCategory) {
        logger(for: category).info("\(message)")
    }

    static func logDebug(_ message: String, category: LogCategory) {
        logger(for: category).debug("\(message)")
    }
}
