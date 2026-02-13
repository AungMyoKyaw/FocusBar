import Foundation
import EventKit

final class ReminderService {
    private let eventStore = EKEventStore()
    var isAuthorized: Bool = false

    init() {
        checkAuthorization()
    }

    func checkAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        isAuthorized = status == .fullAccess || status == .authorized
    }

    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToReminders()
            await MainActor.run { isAuthorized = granted }
            return granted
        } catch {
            return false
        }
    }

    func fetchReminders() async -> [ReminderItem] {
        guard isAuthorized else { return [] }
        return await withCheckedContinuation { continuation in
            let predicate = eventStore.predicateForIncompleteReminders(
                withDueDateStarting: nil, ending: nil, calendars: nil
            )
            eventStore.fetchReminders(matching: predicate) { reminders in
                let items = (reminders ?? []).map { reminder in
                    ReminderItem(
                        id: reminder.calendarItemIdentifier,
                        title: reminder.title ?? "Untitled",
                        listName: reminder.calendar?.title ?? "",
                        isCompleted: reminder.isCompleted
                    )
                }
                continuation.resume(returning: items)
            }
        }
    }

    func searchReminders(query: String) async -> [ReminderItem] {
        let all = await fetchReminders()
        guard !query.isEmpty else { return all }
        return all.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    func createReminder(title: String) async -> ReminderItem? {
        guard isAuthorized else { return nil }
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        do {
            try eventStore.save(reminder, commit: true)
            return ReminderItem(
                id: reminder.calendarItemIdentifier,
                title: title,
                listName: reminder.calendar?.title ?? "",
                isCompleted: false
            )
        } catch {
            return nil
        }
    }

    func appendFocusTime(reminderId: String, minutes: Int, date: Date) async -> Bool {
        guard isAuthorized else { return false }
        guard let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        let note = "FocusBar: \(minutes) min on \(dateStr)"
        reminder.notes = (reminder.notes ?? "") + "\n" + note
        do {
            try eventStore.save(reminder, commit: true)
            return true
        } catch {
            return false
        }
    }

    func markComplete(reminderId: String) async -> Bool {
        guard isAuthorized else { return false }
        guard let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else { return false }
        reminder.isCompleted = true
        do {
            try eventStore.save(reminder, commit: true)
            return true
        } catch {
            return false
        }
    }
}

struct ReminderItem: Identifiable {
    let id: String
    let title: String
    let listName: String
    let isCompleted: Bool
}
