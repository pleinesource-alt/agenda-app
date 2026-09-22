import Foundation
import EventKit
import Combine

enum PlannerMode: String, CaseIterable, Identifiable {
    case day = "Jour"
    case week = "Semaine"
    var id: String { rawValue }
}

@MainActor
final class PlannerViewModel: ObservableObject {
    @Published var mode: PlannerMode = .day
    @Published var referenceDate: Date = Date()
    @Published var editingEvent: EKEvent?
    @Published var isCreatingActivity = false
    @Published var draftStart: Date = Date()
    @Published var draftEnd: Date = Date().addingTimeInterval(3600)

    private let calendarService: CalendarService

    init(calendarService: CalendarService) {
        self.calendarService = calendarService
    }

    var visibleDays: [Date] {
        switch mode {
        case .day:
            return [referenceDate.startOfDay]
        case .week:
            let start = referenceDate.startOfWeek
            return (0..<7).map { start.adding(days: $0) }
        }
    }

    var headerTitle: String {
        switch mode {
        case .day:
            return referenceDate.formatted("EEEE d MMMM")
        case .week:
            let start = referenceDate.startOfWeek
            let end = start.adding(days: 6)
            return "\(start.formatted("d MMM")) – \(end.formatted("d MMM"))"
        }
    }

    func loadVisibleRange() {
        guard let first = visibleDays.first, let last = visibleDays.last else { return }
        let interval = DateInterval(start: first.startOfDay, end: last.adding(days: 1).startOfDay)
        calendarService.loadEvents(in: interval)
    }

    func goToToday() {
        referenceDate = Date()
        loadVisibleRange()
    }

    func step(by amount: Int) {
        switch mode {
        case .day:
            referenceDate = referenceDate.adding(days: amount)
        case .week:
            referenceDate = referenceDate.adding(weeks: amount)
        }
        loadVisibleRange()
    }

    func beginCreatingActivity(start: Date, end: Date) {
        draftStart = start
        draftEnd = end
        editingEvent = nil
        isCreatingActivity = true
    }

    func beginEditing(_ event: EKEvent) {
        editingEvent = event
        draftStart = event.startDate
        draftEnd = event.endDate
        isCreatingActivity = true
    }
}
