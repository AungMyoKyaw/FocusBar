import Foundation
import EventKit
import UserNotifications

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case permissions
    case ready
}

enum PermissionStatus {
    case unknown
    case granted
    case denied
    case skipped
}

@Observable
final class OnboardingViewModel {
    var currentStep: OnboardingStep = .welcome
    var notificationStatus: PermissionStatus = .unknown
    var reminderStatus: PermissionStatus = .unknown

    var isComplete: Bool {
        currentStep == .ready
    }

    func advanceToNext() {
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = nextStep
    }

    func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                notificationStatus = granted ? .granted : .denied
            }
            LoggingService.logInfo(
                "Notification permission \(granted ? "granted" : "denied")",
                category: .permissions
            )
        } catch {
            await MainActor.run { notificationStatus = .denied }
            LoggingService.logError(
                .permissionDenied(.notifications),
                context: "Onboarding notification request failed: \(error.localizedDescription)"
            )
        }
    }

    func requestReminderPermission() async {
        do {
            let store = EKEventStore()
            let granted: Bool
            if #available(macOS 14, *) {
                granted = try await store.requestFullAccessToReminders()
            } else {
                granted = try await store.requestAccess(to: .reminder)
            }
            await MainActor.run {
                reminderStatus = granted ? .granted : .denied
            }
            LoggingService.logInfo(
                "Reminder permission \(granted ? "granted" : "denied")",
                category: .permissions
            )
        } catch {
            await MainActor.run { reminderStatus = .denied }
            LoggingService.logError(
                .permissionDenied(.reminders),
                context: "Onboarding reminder request failed: \(error.localizedDescription)"
            )
        }
    }

    func skipReminders() {
        reminderStatus = .skipped
        LoggingService.logInfo("Reminders skipped during onboarding", category: .permissions)
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasCompletedOnboarding)
        LoggingService.logInfo("Onboarding completed", category: .ui)
    }
}
