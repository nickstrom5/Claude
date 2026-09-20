import SwiftUI

/// One button. Everything else on this screen exists to make you press it again tomorrow.
struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var sessions: SessionManager
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @EnvironmentObject private var store: StoreManager

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showResult = false
    @State private var showDurationPicker = false

    private let presets = [25, 50, 90]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                    if sessions.isActive {
                        ActiveSessionView()
                    } else {
                        idle
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showDurationPicker) {
            DurationPickerSheet(minutes: $appState.preferredMinutes)
                .presentationDetents([.height(360)])
        }
        .sheet(isPresented: $showPaywall) { PaywallView(context: .home, onFinished: { showPaywall = false }) }
        .sheet(isPresented: $showResult) {
            if let finished = sessions.lastFinished {
                SessionResultView(session: finished)
            }
        }
        .onChange(of: sessions.lastFinished) { _, finished in
            if let finished, !finished.isTaste { showResult = true }
        }
        .onChange(of: appState.pendingIntentMinutes) { _, minutes in
            guard let minutes else { return }
            appState.pendingIntentMinutes = nil
            guard !sessions.isActive else { return }
            appState.preferredMinutes = minutes
            Analytics.track(.sessionStartedFromIntent, ["minutes": minutes])
            startTapped()
        }
        .onAppear { appState.consumePendingIntent() }
    }

    /// Streak and settings, laid out inside the content column rather than in the navigation
    /// bar. On a wide screen (the iPhone Duo's inner display) toolbar items pin to the screen
    /// edges while the content sits in a 560pt column, which reads as two unrelated layouts.
    private var header: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill").foregroundStyle(Theme.accent)
                Text("\(appState.stats.streak)")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Theme.surface, in: Capsule())

            Spacer()

            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Theme.surface, in: Circle())
            }
            .buttonStyle(PressScaleStyle())
        }
        .padding(.horizontal, Theme.horizontalPadding)
        .padding(.top, 6)
    }

    private var idle: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.textPrimary)
                Text(todayLine)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.horizontalPadding)
            .padding(.top, 8)

            Spacer()

            // Duration: three presets plus a custom chip that shows whatever was picked.
            let isCustom = !presets.contains(appState.preferredMinutes)
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { minutes in
                    DurationChip(label: "\(minutes)m", selected: appState.preferredMinutes == minutes) {
                        appState.preferredMinutes = minutes
                    }
                }
                DurationChip(label: isCustom ? DurationPickerSheet.label(for: appState.preferredMinutes) : "More…", selected: isCustom) {
                    showDurationPicker = true
                }
            }
            .padding(.horizontal, Theme.horizontalPadding)

            // The button
            Button(action: startTapped) {
                VStack(spacing: 6) {
                    Image(systemName: "flipphone")
                        .font(.system(size: 44, weight: .semibold))
                    Text("Clam up")
                        .font(Theme.Font.display(30))
                }
                .foregroundStyle(.black)
                .frame(width: 220, height: 220)
                .background(Theme.accent)
                .clipShape(Circle())
                .shadow(color: Theme.accent.opacity(0.35), radius: 30, y: 10)
            }
            .buttonStyle(PressScaleStyle())
            .padding(.top, 36)

            Text("\(screenTime.selectedCount) app\(screenTime.selectedCount == 1 ? "" : "s") will lock · fold or lock your phone to focus")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.textTertiary)
                .padding(.top, 18)

            Spacer()

            WeekChart(days: appState.lastSevenDays)
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.bottom, 16)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning."
        case 12..<18: return "Afternoon."
        default: return "Evening."
        }
    }

    private var todayLine: String {
        let minutes = appState.todayMinutes
        if minutes == 0 { return "Nothing clammed up yet today." }
        if minutes >= 60 { return "\(minutes / 60)h \(minutes % 60)m clammed up today." }
        return "\(minutes) min clammed up today."
    }

    private func startTapped() {
        guard store.isPro else {
            Analytics.track(.paywallShown, ["from": "home"])
            showPaywall = true
            return
        }
        guard screenTime.hasSelection else {
            showSettings = true
            return
        }
        sessions.start(minutes: appState.preferredMinutes)
    }
}

/// Seven small bars. Enough to see a streak building, not enough to become a stats app.
struct WeekChart: View {
    let days: [(date: Date, minutes: Int)]

    var body: some View {
        let maxMinutes = max(days.map(\.minutes).max() ?? 1, 30)
        VStack(alignment: .leading, spacing: 10) {
            Text("This week")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.textTertiary)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(day.minutes > 0 ? Theme.accent : Theme.surfaceRaised)
                            .frame(height: max(6, 64 * CGFloat(day.minutes) / CGFloat(maxMinutes)))
                            .frame(maxHeight: 64, alignment: .bottom)
                        Text(day.date, format: .dateTime.weekday(.narrow))
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

private struct DurationChip: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Theme.Font.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(selected ? .black : Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(selected ? Theme.accent : Theme.surface)
                .clipShape(Capsule())
        }
        .buttonStyle(PressScaleStyle())
    }
}

/// Wheel picker for any length from 5 minutes to 4 hours, in 5-minute steps.
struct DurationPickerSheet: View {
    @Binding var minutes: Int
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Int = 25

    static let options: [Int] = Array(stride(from: 5, through: 240, by: 5))

    static func label(for minutes: Int) -> String {
        if minutes >= 60 {
            let h = minutes / 60, m = minutes % 60
            return m == 0 ? "\(h)h" : "\(h)h \(m)m"
        }
        return "\(minutes)m"
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("How long?")
                .font(Theme.Font.title)
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 24)
            Picker("Minutes", selection: $draft) {
                ForEach(Self.options, id: \.self) { value in
                    Text(Self.label(for: value)).tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 160)
            PrimaryButton(title: "Clam up for \(Self.label(for: draft))") {
                minutes = draft
                dismiss()
            }
            .padding(.horizontal, Theme.horizontalPadding)
            .padding(.bottom, 16)
        }
        .background(Theme.background)
        .onAppear {
            draft = Self.options.contains(minutes) ? minutes : 25
        }
    }
}
