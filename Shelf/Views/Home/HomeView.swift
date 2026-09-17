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

    private let presets = [25, 50, 90]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if sessions.isActive {
                    ActiveSessionView()
                } else {
                    idle
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill").foregroundStyle(Theme.accent)
                        Text("\(appState.stats.streak)")
                            .font(Theme.Font.headline)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill").foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showPaywall) { PaywallView(context: .home, onFinished: { showPaywall = false }) }
        .sheet(isPresented: $showResult) {
            if let finished = sessions.lastFinished {
                SessionResultView(session: finished)
            }
        }
        .onChange(of: sessions.lastFinished) { _, finished in
            if let finished, !finished.isTaste { showResult = true }
        }
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

            // Duration
            HStack(spacing: 10) {
                ForEach(presets, id: \.self) { minutes in
                    let selected = appState.preferredMinutes == minutes
                    Button { appState.preferredMinutes = minutes } label: {
                        Text("\(minutes) min")
                            .font(Theme.Font.headline)
                            .foregroundStyle(selected ? .black : Theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(selected ? Theme.accent : Theme.surface)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PressScaleStyle())
                }
            }
            .padding(.horizontal, Theme.horizontalPadding)

            // The button
            Button(action: startTapped) {
                VStack(spacing: 6) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 44, weight: .semibold))
                    Text("Shelf it")
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
        if minutes == 0 { return "Nothing shelved yet today." }
        if minutes >= 60 { return "\(minutes / 60)h \(minutes % 60)m shelved today." }
        return "\(minutes) min shelved today."
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
