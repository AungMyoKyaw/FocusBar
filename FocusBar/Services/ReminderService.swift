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
        if #available(macOS 14, *) {
            isAuthorized = status == .fullAccess
        } else {
            isAuthorized = status == .authorized
        }
        LoggingService.logDebug("Reminder authorization: \(isAuthorized)", category: .permissions)
    }

    func requestAccess() async -> Bool {
        do {
            let granted: Bool
            if #available(macOS 14, *) {
                granted = try await eventStore.requestFullAccessToReminders()
            } else {
                granted = try await eventStore.requestAccess(to: .reminder)
            }
            await MainActor.run { isAuthorized = granted }
            LoggingService.logInfo("Reminder permission \(granted ? "granted" : "denied")", category: .permissions)
            return granted
        } catch {
            LoggingService.logError(.permissionDenied(.reminders), context: "requestAccess failed: \(error.localizedDescription)")
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

    func createReminder(title: String) async throws -> ReminderItem {
        guard isAuthorized else {
            throw AppError.permissionDenied(.reminders)
        }
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        do {
            try eventStore.save(reminder, commit: true)
            LoggingService.logInfo("Reminder created: \(title)", category: .data)
            return ReminderItem(
                id: reminder.calendarItemIdentifier,
                title: title,
                listName: reminder.calendar?.title ?? "",
                isCompleted: false
            )
        } catch {
            LoggingService.logError(.dataError("Failed to save reminder: \(error.localizedDescription)"), context: "createReminder")
            throw AppError.dataError("Failed to create reminder: \(error.localizedDescription)")
        }
    }

    func appendFocusTime(reminderId: String, minutes: Int, date: Date) async throws {
        guard isAuthorized else { throw AppError.permissionDenied(.reminders) }
        guard let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
            throw AppError.dataError("Reminder not found: \(reminderId)")
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        let note = "FocusBar: \(minutes) min on \(dateStr)"
        reminder.notes = (reminder.notes ?? "") + "\n" + note
        do {
            try eventStore.save(reminder, commit: true)
            LoggingService.logDebug("Focus time appended: \(minutes) min to \(reminderId)", category: .data)
        } catch {
            LoggingService.logError(.dataError("Failed to append focus time: \(error.localizedDescription)"), context: "appendFocusTime")
            throw AppError.dataError("Failed to append focus time: \(error.localizedDescription)")
        }
    }

    func markComplete(reminderId: String) async throws {
        guard isAuthorized else { throw AppError.permissionDenied(.reminders) }
        guard let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
            throw AppError.dataError("Reminder not found: \(reminderId)")
        }
        reminder.isCompleted = true
        do {
            try eventStore.save(reminder, commit: true)
            LoggingService.logInfo("Reminder marked complete: \(reminderId)", category: .data)
        } catch {
            LoggingService.logError(.dataError("Failed to mark complete: \(error.localizedDescription)"), context: "markComplete")
            throw AppError.dataError("Failed to mark reminder complete: \(error.localizedDescription)")
        }
    }
}

struct ReminderItem: Identifiable {
    let id: String
    let title: String
    let listName: String
    let isCompleted: Bool
}
