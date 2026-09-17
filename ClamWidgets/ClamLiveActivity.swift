import ActivityKit
import SwiftUI
import WidgetKit

/// The countdown that lives on the Lock Screen / Dynamic Island, and on the iPhone Duo's outer
/// display while folded. Intentionally minimal: a timer and one line. The less there is to look
/// at, the less reason to unfold.
struct ClamLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClamActivityAttributes.self) { context in
            LockScreenView(context: context)
                .activityBackgroundTint(Color(red: 0.07, green: 0.07, blue: 0.09))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Clammed up", systemImage: "flipphone")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.yellow)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.attributes.startDate...context.state.endDate, countsDown: true)
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.state.shieldedCount) apps locked · \(context.state.streak)-day streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "flipphone")
                    .foregroundStyle(.yellow)
            } compactTrailing: {
                Text(timerInterval: context.attributes.startDate...context.state.endDate, countsDown: true)
                    .font(.caption.monospacedDigit())
                    .frame(width: 44)
            } minimal: {
                Image(systemName: "flipphone")
                    .foregroundStyle(.yellow)
            }
        }
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<ClamActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "flipphone")
                .font(.title2)
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("Phone is clammed up")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(context.state.shieldedCount) apps locked · \(context.state.streak)-day streak")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Text(timerInterval: context.attributes.startDate...context.state.endDate, countsDown: true)
                .font(.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
                .frame(width: 96)
        }
        .padding(16)
    }
}
