import AppIntents
import SwiftUI
import WidgetKit

/// Small Home Screen widget: streak + a one-tap "Clam up" button. The button runs the same
/// intent Siri and the Action Button use, which opens the app and starts a session.
struct ClamItWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ClamItWidget", provider: StreakProvider()) { entry in
            ClamItWidgetView(entry: entry)
                .containerBackground(Color(red: 0.07, green: 0.07, blue: 0.09), for: .widget)
        }
        .configurationDisplayName("Clam up")
        .description("Start a session from your Home Screen.")
        .supportedFamilies([.systemSmall])
    }
}

struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let isActive: Bool
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), streak: 7, isActive: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = current()
        // Refresh when the running session should be over, or in 30 minutes, whichever is sooner.
        var next = Date().addingTimeInterval(30 * 60)
        if let end = activeSessionEnd(), end > Date() { next = min(next, end.addingTimeInterval(5)) }
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func activeSessionEnd() -> Date? {
        guard let raw = AppGroup.defaults.string(forKey: AppGroup.Key.activeSessionEnd) else { return nil }
        return ISO8601DateFormatter().date(from: raw)
    }

    private func current() -> StreakEntry {
        let active = activeSessionEnd().map { $0 > Date() } ?? false
        return StreakEntry(date: Date(), streak: AppGroup.defaults.integer(forKey: AppGroup.Key.streak), isActive: active)
    }
}

private struct ClamItWidgetView: View {
    let entry: StreakEntry
    private let accent = Color(red: 0.98, green: 0.82, blue: 0.35)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").foregroundStyle(accent)
                Text("\(entry.streak)")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                Text(entry.streak == 1 ? "day" : "days")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }
            Spacer()
            if entry.isActive {
                Label("Clammed up", systemImage: "flipphone")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
            } else {
                Button(intent: StartClamSessionIntent()) {
                    Text("Clam up")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
