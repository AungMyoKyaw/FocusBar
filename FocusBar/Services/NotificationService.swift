import Foundation
import UserNotifications

@Observable
final class NotificationService {
    var isAuthorized: Bool = false

    init() {
        checkAuthorization()
    }

    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run { isAuthorized = granted }
            LoggingService.logInfo("Notification permission \(granted ? "granted" : "denied")", category: .permissions)
            return granted
        } catch {
            LoggingService.logError(.permissionDenied(.notifications), context: "requestPermission failed: \(error.localizedDescription)")
            return false
        }
    }

    private var bannersAllowed: Bool {
        UserDefaults.standard.bool(forKey: UserDefaultsKeys.bannerEnabled)
    }

    private var soundsAllowed: Bool {
        UserDefaults.standard.bool(forKey: UserDefaultsKeys.soundEnabled)
    }

    func sendSessionComplete(sessionType: SessionType, nextSessionType: SessionType, includeSystemSound: Bool = false) {
        guard bannersAllowed else { return }
        let content = UNMutableNotificationContent()
        content.title = "\(sessionType.displayName) Complete"
        content.body = "Time for \(nextSessionType.displayName)"
        content.sound = (includeSystemSound && soundsAllowed) ? .default : nil

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        LoggingService.logInfo("Sending notification: \(content.title)", category: .timer)
        UNUserNotificationCenter.current().add(request)
    }

    func sendAchievementUnlocked(title: String, xpBonus: Int) {
        guard bannersAllowed else { return }
        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked"
        content.body = "\(title) (+\(xpBonus) XP)"
        content.sound = soundsAllowed ? .default : nil

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        LoggingService.logInfo("Sending notification: \(content.title)", category: .gamification)
        UNUserNotificationCenter.current().add(request)
    }

    func sendLevelUp(level: Int, title: String) {
        guard bannersAllowed else { return }
        let content = UNMutableNotificationContent()
        content.title = "Level Up"
        content.body = "You reached Level \(level): \(title)"
        content.sound = soundsAllowed ? .default : nil

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        LoggingService.logInfo("Sending notification: \(content.title)", category: .gamification)
        UNUserNotificationCenter.current().add(request)
    }

    func sendDailyGoalMet(streak: Int) {
        guard bannersAllowed else { return }
        let content = UNMutableNotificationContent()
        content.title = "Daily Goal Met"
        content.body = "You're on a \(streak)-day streak"
        content.sound = soundsAllowed ? .default : nil

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        LoggingService.logInfo("Sending notification: \(content.title)", category: .gamification)
        UNUserNotificationCenter.current().add(request)
    }

    func sendFocusGuardNudge(appName: String, taskTitle: String?) {
        guard bannersAllowed else { return }
        let content = UNMutableNotificationContent()
        content.title = "Focus Guard: \(appName)"
        if let taskTitle, !taskTitle.isEmpty {
            content.body = "Stay locked in on \"\(taskTitle)\""
        } else {
            content.body = "You are currently in a Focus session"
        }
        content.sound = nil

        let request = UNNotificationRequest(identifier: "focusbar.guard.\(appName)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
