import AppKit
import Foundation

@Observable
final class RemindersViewModel {
    let reminderService = ReminderService()
    var reminders: [ReminderItem] = []
    var searchQuery: String = ""
    var selectedReminder: ReminderItem?
    var quickAddText: String = ""
    var currentError: AppError?

    var isAuthorized: Bool { reminderService.isAuthorized }
    var isDenied: Bool { reminderService.isDenied }

    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders") {
            NSWorkspace.shared.open(url)
        }
    }

    func loadReminders() async {
        if searchQuery.isEmpty {
            reminders = await reminderService.fetchReminders()
        } else {
            reminders = await reminderService.searchReminders(query: searchQuery)
        }
    }

    func requestAccess() async {
        let granted = await reminderService.requestAccess()
        if granted {
            currentError = nil
            await loadReminders()
        } else {
            currentError = .permissionDenied(.reminders)
        }
    }

    func createQuickTask() async {
        guard !quickAddText.isEmpty else { return }
        do {
            let item = try await reminderService.createReminder(title: quickAddText)
            selectedReminder = item
            quickAddText = ""
            await loadReminders()
        } catch {
            if let appError = error as? AppError {
                currentError = appError
                LoggingService.logError(appError, context: "createQuickTask")
            }
        }
    }

    func logFocusTime(minutes: Int) async {
        guard let reminder = selectedReminder else { return }
        do {
            try await reminderService.appendFocusTime(reminderId: reminder.id, minutes: minutes, date: Date())
        } catch {
            if let appError = error as? AppError {
                currentError = appError
                LoggingService.logError(appError, context: "logFocusTime")
            }
        }
    }

    func completeSelectedReminder() async {
        guard let reminder = selectedReminder else { return }
        do {
            try await reminderService.markComplete(reminderId: reminder.id)
            selectedReminder = nil
            await loadReminders()
        } catch {
            if let appError = error as? AppError {
                currentError = appError
                LoggingService.logError(appError, context: "completeSelectedReminder")
            }
        }
    }
}
