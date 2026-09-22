import SwiftUI

/// Playful pill toggles — one per Mac calendar — so activities can be
/// shown/hidden by color without leaving the timeline.
struct CalendarFilterChips: View {
    @EnvironmentObject private var calendarService: CalendarService

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(calendarService.calendars, id: \.calendarIdentifier) { calendar in
                    let isOn = calendarService.visibleCalendarIDs.contains(calendar.calendarIdentifier)
                    Button {
                        Haptics.tap()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            calendarService.toggleCalendarVisibility(calendar)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(calendarService.color(for: calendar))
                                .frame(width: 8, height: 8)
                            Text(calendar.title)
                                .font(.footnote.weight(.medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isOn ? calendarService.color(for: calendar).opacity(0.18) : Color.gray.opacity(0.1))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(isOn ? calendarService.color(for: calendar) : .clear, lineWidth: 1.5)
                        )
                        .opacity(isOn ? 1 : 0.5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}
