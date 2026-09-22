import SwiftUI
import EventKit

struct WeekView: View {
    @EnvironmentObject private var calendarService: CalendarService
    @ObservedObject var planner: PlannerViewModel

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 0) {
                TimelineRuler()
                    .padding(.top, 34)

                ForEach(planner.visibleDays, id: \.self) { day in
                    VStack(spacing: 4) {
                        dayHeader(for: day)
                        ZStack(alignment: .topLeading) {
                            HourGridLines()
                            ForEach(calendarService.events(on: day), id: \.eventIdentifier) { event in
                                ActivityBlockView(
                                    event: event,
                                    color: calendarService.color(for: event.calendar),
                                    compact: true
                                ) {
                                    planner.beginEditing(event)
                                }
                                .offset(y: TimelineMetrics.yOffset(for: max(event.startDate, day)))
                                .padding(.trailing, 2)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
    }

    private func dayHeader(for day: Date) -> some View {
        VStack(spacing: 2) {
            Text(day.formatted("EEE"))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(day.formatted("d"))
                .font(.subheadline.weight(day.isToday ? .bold : .regular))
                .frame(width: 26, height: 26)
                .background(day.isToday ? Color.accentColor : .clear)
                .clipShape(Circle())
                .foregroundStyle(day.isToday ? .white : .primary)
        }
        .frame(height: 34)
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap()
            planner.referenceDate = day
            planner.mode = .day
        }
    }
}
