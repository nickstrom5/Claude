import SwiftUI

/// What you see if you unlock the phone mid-session. Calm, and a little bit judgmental.
struct ActiveSessionView: View {
    @EnvironmentObject private var sessions: SessionManager
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var screenTime: ScreenTimeManager

    @State private var holdProgress: Double = 0
    @State private var holdTask: Task<Void, Never>?

    var body: some View {
        if let session = sessions.active {
            VStack(spacing: 0) {
                Spacer()
                CountdownRing(start: session.start, end: session.plannedEnd)
                    .frame(width: 280, height: 280)
                Text("\(screenTime.selectedCount) apps clammed up")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 28)
                Text("Fold it back up. The timer is on your lock screen.")
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
                Spacer()

                holdToExit
                    .padding(.horizontal, Theme.horizontalPadding)
                    .padding(.bottom, 16)
            }
        }
    }

    private var holdToExit: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.surface)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.danger.opacity(0.35))
                    .scaleEffect(x: holdProgress, y: 1, anchor: .leading)
                Text(holdProgress > 0 ? "Keep holding… \(Int((1 - holdProgress) * SessionManager.earlyExitHoldSeconds) + 1)s" : "Hold 10s to give up")
                    .font(Theme.Font.headline)
                    .foregroundStyle(holdProgress > 0 ? Theme.danger : Theme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 54)
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: SessionManager.earlyExitHoldSeconds, maximumDistance: 50) {
                cancelHold()
                sessions.abandon()
            } onPressingChanged: { pressing in
                if pressing { beginHold() } else { cancelHold() }
            }

            if appState.stats.streak > 0 {
                Text("Giving up resets your \(appState.stats.streak)-day streak.")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }

    private func beginHold() {
        holdTask?.cancel()
        holdTask = Task {
            let steps = 100
            for i in 1...steps {
                try? await Task.sleep(nanoseconds: UInt64(SessionManager.earlyExitHoldSeconds * 1_000_000_000 / Double(steps)))
                guard !Task.isCancelled else { return }
                withAnimation(.linear(duration: 0.1)) { holdProgress = Double(i) / Double(steps) }
            }
        }
    }

    private func cancelHold() {
        holdTask?.cancel()
        holdTask = nil
        withAnimation(.easeOut(duration: 0.2)) { holdProgress = 0 }
    }
}

/// Shown after a real session ends. Result + share = the retention and distribution loop in one.
struct SessionResultView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let session: FocusSession
    @State private var showShare = false
    /// Measured so the 300pt card is laid out at the size it is drawn, and shrinks further on an
    /// iPhone SE. scaleEffect alone only changes the drawing, so the layout still reserved 300pt.
    @State private var availableHeight: CGFloat = 900
    private var cardScale: CGFloat { availableHeight < 700 ? 0.7 : 0.9 }

    var body: some View {
        VStack(spacing: 0) {
            // The outer display of a folded iPhone Duo is short: centre the hero when it fits,
            // scroll it when it does not, so nothing is clipped off the top.
            ViewThatFits(in: .vertical) {
                VStack(spacing: 0) {
                    Spacer()
                    hero
                    Spacer()
                }
                ScrollView {
                    hero.padding(.vertical, 16)
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            if session.completed {
                PrimaryButton(title: "Share") {
                    Analytics.track(.shareTapped, ["from": "result"])
                    showShare = true
                }
                .padding(.bottom, 8)
            }
            SecondaryButton(title: "Done") { dismiss() }
                .padding(.bottom, 16)
        }
        .padding(.horizontal, Theme.horizontalPadding)
        .background(Theme.background)
        .background(GeometryReader { geo in
            Color.clear
                .onAppear { availableHeight = geo.size.height }
                .onChange(of: geo.size.height) { _, h in availableHeight = h }
        })
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [ShareCardView(title: "I clammed up my phone", detail: "for \(session.formattedDuration)", streak: appState.stats.streak).render()].compactMap { $0 })
        }
    }

    @ViewBuilder private var hero: some View {
        VStack(spacing: 0) {
            Image(systemName: session.completed ? "checkmark.seal.fill" : "arrow.uturn.backward.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(session.completed ? Theme.success : Theme.danger)
            Text(session.completed ? "Clammed up for \(session.formattedDuration)." : "Stopped at \(session.formattedDuration).")
                .font(Theme.Font.title)
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 18)
            Text(session.completed
                 ? "\(appState.stats.streak)-day streak. \(appState.stats.totalFormatted) clammed up total."
                 : "Streak reset. Tomorrow's a new day.")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.textSecondary)
                .padding(.top, 6)

            if session.completed, !appState.lastAchievements.isEmpty {
                AchievementsRow(achievements: appState.lastAchievements)
                    .padding(.top, 14)
            }

            if session.completed {
                ShareCardView(title: "I clammed up my phone", detail: "for \(session.formattedDuration)", streak: appState.stats.streak)
                    .scaleEffect(cardScale)
                    .frame(width: 300 * cardScale, height: 300 * cardScale)
                    .padding(.top, cardScale < 0.9 ? 16 : 28)
            }
        }
    }
}

/// "New record" / "Badge unlocked" chips on the result screen. The moment people screenshot.
struct AchievementsRow: View {
    let achievements: Stats.Achievements

    var body: some View {
        VStack(spacing: 8) {
            ForEach(achievements.records) { record in
                chip(symbol: "trophy.fill", text: "New record: \(record.title.lowercased())")
            }
            ForEach(achievements.badges) { badge in
                chip(symbol: badge.symbol, text: "Badge unlocked: \(badge.title)")
            }
        }
    }

    private func chip(symbol: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).foregroundStyle(Theme.accent)
            Text(text).font(Theme.Font.headline).foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.accentSoft)
        .clipShape(Capsule())
    }
}
