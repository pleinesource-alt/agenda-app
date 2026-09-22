import SwiftUI
import EventKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A single colored activity on the timeline — the core "visual, at a
/// glance" unit of the whole app.
struct ActivityBlockView: View {
    let event: EKEvent
    let color: Color
    let compact: Bool
    var onTap: () -> Void

    private var height: CGFloat {
        let minutes = event.endDate.timeIntervalSince(event.startDate) / 60
        return max(CGFloat(minutes) / 60 * TimelineMetrics.hourHeight, 22)
    }

    var body: some View {
        Button(action: {
            Haptics.tap()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title ?? "Sans titre")
                    .font(.caption.weight(.semibold))
                    .lineLimit(compact ? 1 : 2)
                if !compact && height > 36 {
                    Text(timeRangeText)
                        .font(.caption2)
                        .opacity(0.8)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: height, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.85))
            )
            .foregroundStyle(color.isLight ? Color.black.opacity(0.85) : .white)
            .shadow(color: color.opacity(0.35), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var timeRangeText: String {
        "\(event.startDate.formatted("HH:mm")) – \(event.endDate.formatted("HH:mm"))"
    }
}

extension Color {
    /// Rough luminance check so block text stays readable on any
    /// calendar color, light or dark.
    var isLight: Bool {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance > 0.6
        #elseif canImport(AppKit)
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? .white
        let luminance = 0.299 * nsColor.redComponent + 0.587 * nsColor.greenComponent + 0.114 * nsColor.blueComponent
        return luminance > 0.6
        #else
        return false
        #endif
    }
}
