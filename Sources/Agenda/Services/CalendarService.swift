import EventKit
import Combine
import SwiftUI

/// Bridges the app to the system Calendar store (EventKit), so every
/// activity read or written here is the same data macOS/iOS Calendar
/// shows and syncs via iCloud — no separate sync layer needed.
@MainActor
final class CalendarService: ObservableObject {
    @Published private(set) var authorizationStatus: EKAuthorizationStatus
    @Published private(set) var calendars: [EKCalendar] = []
    @Published private(set) var events: [EKEvent] = []
    @Published var visibleCalendarIDs: Set<String> = []

    private let store = EKEventStore()
    private var changeObserver: NSObjectProtocol?
    private var loadedRange: DateInterval?

    init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        observeStoreChanges()
    }

    deinit {
        if let changeObserver {
            NotificationCenter.default.removeObserver(changeObserver)
        }
    }

    func requestAccessIfNeeded() async {
        guard authorizationStatus != .fullAccess else {
            refreshCalendars()
            return
        }
        do {
            let granted = try await store.requestFullAccessToEvents()
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            if granted {
                refreshCalendars()
            }
        } catch {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        }
    }

    func refreshCalendars() {
        calendars = store.calendars(for: .event)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        if visibleCalendarIDs.isEmpty {
            visibleCalendarIDs = Set(calendars.map(\.calendarIdentifier))
        }
    }

    /// Loads every event overlapping `interval`, widened a little so a
    /// day/week view scrolled slightly still has data on hand.
    func loadEvents(in interval: DateInterval) {
        guard authorizationStatus == .fullAccess else { return }
        let padded = DateInterval(
            start: interval.start.addingTimeInterval(-2 * 86400),
            end: interval.end.addingTimeInterval(2 * 86400)
        )
        loadedRange = padded
        let predicate = store.predicateForEvents(withStart: padded.start, end: padded.end, calendars: nil)
        events = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }

    func events(on day: Date, calendar: Calendar = .current) -> [EKEvent] {
        let dayInterval = calendar.dateInterval(of: .day, for: day) ?? DateInterval(start: day, duration: 86400)
        return events.filter {
            visibleCalendarIDs.contains($0.calendar.calendarIdentifier) &&
            $0.startDate < dayInterval.end && $0.endDate > dayInterval.start
        }
    }

    @discardableResult
    func createActivity(title: String, start: Date, end: Date, calendar: EKCalendar, notes: String? = nil) throws -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = start
        event.endDate = end
        event.calendar = calendar
        event.notes = notes
        try store.save(event, span: .thisEvent)
        reloadCurrentRange()
        return event
    }

    func update(_ event: EKEvent, title: String, start: Date, end: Date, calendar: EKCalendar) throws {
        event.title = title
        event.startDate = start
        event.endDate = end
        event.calendar = calendar
        try store.save(event, span: .thisEvent)
        reloadCurrentRange()
    }

    func delete(_ event: EKEvent) throws {
        try store.remove(event, span: .thisEvent)
        reloadCurrentRange()
    }

    func toggleCalendarVisibility(_ calendar: EKCalendar) {
        if visibleCalendarIDs.contains(calendar.calendarIdentifier) {
            visibleCalendarIDs.remove(calendar.calendarIdentifier)
        } else {
            visibleCalendarIDs.insert(calendar.calendarIdentifier)
        }
    }

    func color(for calendar: EKCalendar) -> Color {
        Color(cgColor: calendar.cgColor)
    }

    var defaultCalendarForNewActivities: EKCalendar? {
        store.defaultCalendarForNewEvents
    }

    private func reloadCurrentRange() {
        if let loadedRange {
            loadEvents(in: loadedRange)
        }
    }

    private func observeStoreChanges() {
        changeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            // queue: .main above guarantees we're already on the main
            // actor here, so assumeIsolated avoids spawning a Task
            // (which would otherwise trip Swift's concurrency checker
            // on the weakly-captured self).
            MainActor.assumeIsolated {
                self?.refreshCalendars()
                self?.reloadCurrentRange()
            }
        }
    }
}
