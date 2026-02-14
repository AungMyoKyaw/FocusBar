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

    func loadReminders() async {
        if searchQuery.isEmpty {
            reminders = await reminderService.fetchReminders()
        } else {
            reminders = await reminderService.searchReminders(query: searchQuery)
        }
    }

    func requestAccess() async {
        _ = await reminderService.requestAccess()
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
}
