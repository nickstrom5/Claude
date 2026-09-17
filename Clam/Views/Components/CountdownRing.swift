import SwiftUI

/// Big ring + system-driven countdown text. `Text(timerInterval:)` updates itself, so the
/// view doesn't need a timer to stay accurate.
struct CountdownRing: View {
    let start: Date
    let end: Date
    var lineWidth: CGFloat = 14

    var body: some View {
        TimelineView(.periodic(from: start, by: 1)) { context in
            let total = end.timeIntervalSince(start)
            let elapsed = min(max(context.date.timeIntervalSince(start), 0), total)
            let progress = total > 0 ? elapsed / total : 1

            ZStack {
                Circle()
                    .stroke(Theme.surfaceRaised, lineWidth: lineWidth)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                VStack(spacing: 6) {
                    Text(timerInterval: start...end, countsDown: true)
                        .font(Theme.Font.mono(52))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("left")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
    }
}
