import Foundation
import EventKit

final class CalendarService {
    private let eventStore = EKEventStore()
    var isAuthorized: Bool = false

    init() {
        checkAuthorization()
    }

    func checkAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(macOS 14, *) {
            isAuthorized = status == .fullAccess || status == .writeOnly
        } else {
            isAuthorized = status == .authorized
        }
    }

    func requestAccess() async -> Bool {
        do {
            let granted: Bool
            if #available(macOS 14, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }
            await MainActor.run { isAuthorized = granted }
            LoggingService.logInfo("Calendar permission \(granted ? "granted" : "denied")", category: .permissions)
            return granted
        } catch {
            LoggingService.logError(.dataError("Calendar permission failed: \(error.localizedDescription)"), context: "CalendarService.requestAccess")
            return false
        }
    }

    func logCompletedSession(
        title: String,
        startDate: Date,
        endDate: Date,
        notes: String?,
        calendarName: String
    ) async {
        checkAuthorization()
        if !isAuthorized {
            let granted = await requestAccess()
            guard granted else { return }
        }

        let targetCalendar = findOrCreateCalendar(named: calendarName) ?? eventStore.defaultCalendarForNewEvents
        guard let targetCalendar else { return }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = targetCalendar
        event.title = title
        event.startDate = startDate
        event.endDate = max(startDate.addingTimeInterval(60), endDate)
        event.notes = notes

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            LoggingService.logInfo("Logged focus block to calendar '\(targetCalendar.title)'", category: .data)
        } catch {
            LoggingService.logError(.dataError("Calendar save failed: \(error.localizedDescription)"), context: "CalendarService.logCompletedSession")
        }
    }

    private func findOrCreateCalendar(named name: String) -> EKCalendar? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let existing = eventStore.calendars(for: .event).first(where: { $0.title == trimmed }) {
            return existing
        }

        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = trimmed
        calendar.source = eventStore.defaultCalendarForNewEvents?.source
            ?? eventStore.sources.first(where: { $0.sourceType == .local || $0.sourceType == .calDAV })

        do {
            try eventStore.saveCalendar(calendar, commit: true)
            return calendar
        } catch {
            LoggingService.logDebug("Could not create calendar '\(trimmed)', falling back to default", category: .data)
            return nil
        }
    }
}
