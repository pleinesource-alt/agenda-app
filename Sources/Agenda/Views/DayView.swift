import SwiftUI
import EventKit

struct DayView: View {
    @EnvironmentObject private var calendarService: CalendarService
    @ObservedObject var planner: PlannerViewModel
    let day: Date

    @State private var dragAnchor: Date?
    @State private var dragCurrent: Date?
    @State private var moveDrag: ActiveDrag?
    @State private var resizeDrag: ActiveDrag?

    private struct ActiveDrag {
        let eventID: String
        var translation: CGFloat
    }

    private var events: [EKEvent] {
        calendarService.events(on: day)
    }

    var body: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                HStack(alignment: .top, spacing: 8) {
                    TimelineRuler()
                    ZStack(alignment: .topLeading) {
                        HourGridLines()
                            .padding(.trailing)

                        ForEach(events, id: \.eventIdentifier) { event in
                            let isMoving = moveDrag?.eventID == event.eventIdentifier
                            let isResizing = resizeDrag?.eventID == event.eventIdentifier
                            ActivityBlockView(
                                event: event,
                                color: calendarService.color(for: event.calendar),
                                compact: false,
                                showsResizeHandle: true,
                                resizeDelta: isResizing ? resizeDrag!.translation : 0,
                                onTap: {
                                    planner.beginEditing(event)
                                },
                                onMoveChanged: { translation in
                                    moveDrag = ActiveDrag(eventID: event.eventIdentifier, translation: translation)
                                },
                                onMoveEnded: { translation in
                                    commitMove(event: event, translation: translation)
                                    moveDrag = nil
                                },
                                onResizeChanged: { translation in
                                    resizeDrag = ActiveDrag(eventID: event.eventIdentifier, translation: translation)
                                },
                                onResizeEnded: { translation in
                                    commitResize(event: event, translation: translation)
                                    resizeDrag = nil
                                }
                            )
                            .padding(.trailing, 8)
                            .offset(y: TimelineMetrics.yOffset(for: max(event.startDate, day)) + (isMoving ? moveDrag!.translation : 0))
                            .animation(.interactiveSpring(), value: isMoving)
                        }

                        if let dragAnchor, let dragCurrent {
                            let start = min(dragAnchor, dragCurrent)
                            let end = max(dragAnchor, dragCurrent)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accentColor.opacity(0.25))
                                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.accentColor, lineWidth: 1.5))
                                .frame(height: max(TimelineMetrics.yOffset(for: end) - TimelineMetrics.yOffset(for: start), 20))
                                .offset(y: TimelineMetrics.yOffset(for: start))
                                .padding(.trailing, 8)
                                .allowsHitTesting(false)
                        }

                        if day.isToday {
                            NowIndicator()
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(dragToCreateGesture)
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
        }
    }

    private var dragToCreateGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let anchorTime = time(forY: value.startLocation.y)
                let currentTime = time(forY: value.location.y)
                if dragAnchor == nil {
                    dragAnchor = anchorTime
                }
                dragCurrent = currentTime
            }
            .onEnded { _ in
                guard let dragAnchor, let dragCurrent else { return }
                let start = min(dragAnchor, dragCurrent)
                let end = max(dragAnchor, dragCurrent)
                let minimumEnd = start.addingTimeInterval(15 * 60)
                Haptics.success()
                planner.beginCreatingActivity(start: start, end: max(end, minimumEnd))
                self.dragAnchor = nil
                self.dragCurrent = nil
            }
    }

    private func time(forY y: CGFloat) -> Date {
        let minutes = max(0, min(24 * 60, y / TimelineMetrics.hourHeight * 60))
        let date = day.startOfDay.addingTimeInterval(TimeInterval(minutes * 60))
        return date.roundedToNearest(minutes: 15)
    }

    private func commitMove(event: EKEvent, translation: CGFloat) {
        let deltaMinutes = Double(translation / TimelineMetrics.hourHeight * 60)
        let newStart = event.startDate.addingTimeInterval(deltaMinutes * 60).roundedToNearest(minutes: 15)
        guard newStart != event.startDate else { return }
        let duration = event.endDate.timeIntervalSince(event.startDate)
        let newEnd = newStart.addingTimeInterval(duration)
        do {
            try calendarService.update(event, title: event.title ?? "", start: newStart, end: newEnd, calendar: event.calendar)
            Haptics.success()
        } catch {
            // Best-effort: the block will snap back on the next refresh.
        }
    }

    private func commitResize(event: EKEvent, translation: CGFloat) {
        let deltaMinutes = Double(translation / TimelineMetrics.hourHeight * 60)
        var newEnd = event.endDate.addingTimeInterval(deltaMinutes * 60).roundedToNearest(minutes: 15)
        let minimumEnd = event.startDate.addingTimeInterval(15 * 60)
        if newEnd < minimumEnd { newEnd = minimumEnd }
        guard newEnd != event.endDate else { return }
        do {
            try calendarService.update(event, title: event.title ?? "", start: event.startDate, end: newEnd, calendar: event.calendar)
            Haptics.success()
        } catch {
            // Best-effort: the block will snap back on the next refresh.
        }
    }
}

/// A thin red line marking "now", like Calendar.app, so today's column
/// reads instantly at a glance.
private struct NowIndicator: View {
    @State private var now = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        Rectangle()
            .fill(Color.red)
            .frame(height: 2)
            .offset(y: TimelineMetrics.yOffset(for: now))
            .allowsHitTesting(false)
            .onReceive(timer) { now = $0 }
    }
}
