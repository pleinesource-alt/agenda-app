import SwiftUI
import EventKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A single colored activity on the timeline — the core "visual, at a
/// glance" unit of the whole app. Supports dragging to move (whole
/// block) and dragging the bottom handle to resize.
struct ActivityBlockView: View {
    let event: EKEvent
    let color: Color
    let compact: Bool
    var showsResizeHandle: Bool = false
    var resizeDelta: CGFloat = 0
    var onTap: () -> Void
    var onMoveChanged: (CGFloat) -> Void = { _ in }
    var onMoveEnded: (CGFloat) -> Void = { _ in }
    var onResizeChanged: (CGFloat) -> Void = { _ in }
    var onResizeEnded: (CGFloat) -> Void = { _ in }

    private var baseHeight: CGFloat {
        let minutes = event.endDate.timeIntervalSince(event.startDate) / 60
        return CGFloat(minutes) / 60 * TimelineMetrics.hourHeight
    }

    private var height: CGFloat {
        max(baseHeight + resizeDelta, 22)
    }

    /// While resizing, reflects the live end time so the label updates
    /// as you drag — otherwise just the event's real end time.
    private var displayEnd: Date {
        guard resizeDelta != 0 else { return event.endDate }
        let minutes = Double(height) / Double(TimelineMetrics.hourHeight) * 60
        return event.startDate.addingTimeInterval(minutes * 60)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
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
            .contentShape(Rectangle())
            .onTapGesture {
                Haptics.tap()
                onTap()
            }
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { onMoveChanged($0.translation.height) }
                    .onEnded { onMoveEnded($0.translation.height) }
            )

            if showsResizeHandle {
                Capsule()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 26, height: 4)
                    .padding(.bottom, 3)
                    .contentShape(Rectangle().inset(by: -8))
                    .gesture(
                        DragGesture(minimumDistance: 2)
                            .onChanged { onResizeChanged($0.translation.height) }
                            .onEnded { onResizeEnded($0.translation.height) }
                    )
            }
        }
    }

    private var timeRangeText: String {
        "\(event.startDate.formatted("HH:mm")) – \(displayEnd.formatted("HH:mm"))"
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
