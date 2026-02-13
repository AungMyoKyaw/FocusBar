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
            return granted
        } catch {
            return false
        }
    }

    func sendSessionComplete(sessionType: SessionType, nextSessionType: SessionType) {
        let content = UNMutableNotificationContent()
        content.title = "\(sessionType.displayName) Complete!"
        content.body = "Time for \(nextSessionType.displayName)"
        content.sound = UserDefaults.standard.bool(forKey: UserDefaultsKeys.soundEnabled) ? .default : nil

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func sendAchievementUnlocked(title: String, xpBonus: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked!"
        content.body = "\(title) (+\(xpBonus) XP)"
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func sendLevelUp(level: Int, title: String) {
        let content = UNMutableNotificationContent()
        content.title = "Level Up!"
        content.body = "You reached Level \(level): \(title)"
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func sendDailyGoalMet(streak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Daily Goal Met!"
        content.body = "You're on a \(streak)-day streak!"
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
