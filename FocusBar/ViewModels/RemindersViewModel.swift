import Foundation

@Observable
final class RemindersViewModel {
    let reminderService = ReminderService()
    var reminders: [ReminderItem] = []
    var searchQuery: String = ""
    var selectedReminder: ReminderItem?
    var quickAddText: String = ""

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
        if let item = await reminderService.createReminder(title: quickAddText) {
            selectedReminder = item
            quickAddText = ""
            await loadReminders()
        }
    }

    func logFocusTime(minutes: Int) async {
        guard let reminder = selectedReminder else { return }
        _ = await reminderService.appendFocusTime(reminderId: reminder.id, minutes: minutes, date: Date())
    }
}
