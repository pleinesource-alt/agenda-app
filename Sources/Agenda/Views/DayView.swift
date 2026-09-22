import SwiftUI
import EventKit

struct DayView: View {
    @EnvironmentObject private var calendarService: CalendarService
    @ObservedObject var planner: PlannerViewModel
    let day: Date

    @State private var dragAnchor: Date?
    @State private var dragCurrent: Date?

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
                            ActivityBlockView(
                                event: event,
                                color: calendarService.color(for: event.calendar),
                                compact: false
                            ) {
                                planner.beginEditing(event)
                            }
                            .padding(.trailing, 8)
                            .offset(y: TimelineMetrics.yOffset(for: max(event.startDate, day)))
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
