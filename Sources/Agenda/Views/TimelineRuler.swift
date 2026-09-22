import SwiftUI

enum TimelineMetrics {
    static let hourHeight: CGFloat = 64
    static let rulerWidth: CGFloat = 48
    static var dayHeight: CGFloat { hourHeight * 24 }

    static func yOffset(for date: Date) -> CGFloat {
        date.minutesSinceMidnight / 60 * hourHeight
    }
}

/// Hour labels running down the left edge of a day column.
struct TimelineRuler: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<24, id: \.self) { hour in
                Text(String(format: "%02d:00", hour))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: TimelineMetrics.rulerWidth, alignment: .trailing)
                    .offset(y: CGFloat(hour) * TimelineMetrics.hourHeight - 6)
            }
        }
        .frame(width: TimelineMetrics.rulerWidth, height: TimelineMetrics.dayHeight, alignment: .topLeading)
    }
}

/// Faint horizontal hour lines behind the activity blocks.
struct HourGridLines: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { _ in
                Divider()
                Spacer(minLength: TimelineMetrics.hourHeight - 1)
            }
        }
        .frame(height: TimelineMetrics.dayHeight)
    }
}
