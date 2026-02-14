import Foundation

enum PermissionType: String {
    case notifications
    case reminders
}

enum AppError: LocalizedError, Identifiable {
    case dataError(String)
    case permissionDenied(PermissionType)
    case exportFailed(String)
    case unknown(String)

    var id: String {
        switch self {
        case .dataError(let msg): return "dataError-\(msg)"
        case .permissionDenied(let type): return "permissionDenied-\(type.rawValue)"
        case .exportFailed(let msg): return "exportFailed-\(msg)"
        case .unknown(let msg): return "unknown-\(msg)"
        }
    }

    var errorDescription: String? {
        switch self {
        case .dataError:
            return "Couldn't save your progress. Please try again."
        case .permissionDenied(let type):
            return "FocusBar needs \(type.rawValue) access. Enable it in System Settings."
        case .exportFailed:
            return "Export failed. Please try saving to a different location."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }

    var debugDescription: String {
        switch self {
        case .dataError(let msg):
            return "DataError: \(msg)"
        case .permissionDenied(let type):
            return "PermissionDenied: \(type.rawValue)"
        case .exportFailed(let msg):
            return "ExportFailed: \(msg)"
        case .unknown(let msg):
            return "Unknown: \(msg)"
        }
    }
}
