import FamilyControls
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showPicker = false
    @State private var showPaywall = false
    @State private var confirmUnlock = false
    @State private var analyticsOn = !Analytics.isOptedOut

    var body: some View {
        NavigationStack {
            List {
                Section("Clammed up apps") {
                    Button {
                        if ScreenTimeManager.isSimulator {
                            screenTime.simulatedSelectionCount = screenTime.hasSelection ? 0 : 4
                            return
                        }
                        Task {
                            var allowed = screenTime.isAuthorized
                            if !allowed { allowed = await screenTime.requestAuthorization() }
                            if allowed { showPicker = true }
                        }
                    } label: {
                        HStack {
                            Text("Apps to lock")
                            Spacer()
                            Text("\(screenTime.selectedCount)").foregroundStyle(Theme.textSecondary)
                            Image(systemName: "chevron.right").foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .foregroundStyle(Theme.textPrimary)
                }

                Section("Records") {
                    LabeledContent("Current streak", value: "\(appState.stats.streak) days")
                    LabeledContent("Longest streak", value: "\(appState.stats.longestStreak) days")
                    LabeledContent("Longest session", value: Stats.format(minutes: appState.stats.longestSessionMinutes))
                    LabeledContent("Best day", value: Stats.format(minutes: appState.stats.bestDayMinutes))
                    LabeledContent("Total clammed up", value: appState.stats.totalFormatted)
                    LabeledContent("Sessions", value: "\(appState.stats.sessionsCompleted)")
                }

                Section("Badges") {
                    BadgeGrid(stats: appState.stats)
                        .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                }

                Section("Plan") {
                    if store.isPro {
                        LabeledContent("Clam Pro", value: "Active")
                        Button("Manage subscription") {
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        }
                    } else {
                        Button("Upgrade to Clam Pro") { showPaywall = true }
                    }
                    Button("Restore purchases") { Task { await store.restore() } }
                }

                // The escape hatch. Clam's whole job is making apps hard to reach, so there has
                // to be one obvious, always-available way out that does not depend on the
                // timer, the monitor extension or any of this working correctly.
                Section {
                    Button("Unlock everything now", role: .destructive) { confirmUnlock = true }
                } footer: {
                    Text("Clears the block immediately and ends any running session. Use this if your apps are still locked when they shouldn't be.")
                }

                Section {
                    Toggle("Anonymous analytics", isOn: $analyticsOn)
                        .onChange(of: analyticsOn) { _, on in
                            Analytics.isOptedOut = !on
                            Analytics.installSinks()
                        }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Counts like \"session started\" so we can tell which parts of Clam work. Never which apps you lock. Turn it off and nothing leaves your phone.")
                }

                HelpSection()

                Section {
                    Link("Privacy policy", destination: URL(string: "https://getclam.app/privacy.html")!)
                    Link("Terms", destination: URL(string: "https://getclam.app/terms.html")!)
                    Link("Created by Nick Soderstrom", destination: URL(string: "https://work-with-nick.com")!)
                } footer: {
                    Text("Clam \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") · Everything stays on your phone.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Unlock everything?", isPresented: $confirmUnlock) {
                Button("Unlock", role: .destructive) { unlockEverything() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your apps come back right away and any running session ends without counting.")
            }
            .familyActivityPicker(isPresented: $showPicker, selection: $screenTime.selection)
            .sheet(isPresented: $showPaywall) {
                PaywallView(context: .home, onFinished: { showPaywall = false })
            }
        }
    }

    /// Belt and braces: clear the shield, stop the monitor, and wipe the session keys so a
    /// restore cannot bring the block back.
    private func unlockEverything() {
        screenTime.clearShield()
        screenTime.cancelShieldRemoval()
        let defaults = AppGroup.defaults
        for key in [AppGroup.Key.activeSessionEnd, AppGroup.Key.activeSessionMinutes,
                    AppGroup.Key.activeSessionStart, AppGroup.Key.activeSessionIsTaste,
                    AppGroup.Key.finishedWhileAway] {
            defaults.removeObject(forKey: key)
        }
        Analytics.track(.manualUnlock)
        dismiss()
    }
}

/// All badges, earned ones lit. Unearned ones stay visible so the next goal is obvious.
struct BadgeGrid: View {
    let stats: Stats
    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Badge.allCases) { badge in
                let earned = stats.unlockedBadges.contains(badge.rawValue) || badge.isEarned(by: stats)
                VStack(spacing: 6) {
                    Image(systemName: badge.symbol)
                        .font(.title2)
                        .foregroundStyle(earned ? Theme.accent : Theme.textTertiary)
                    Text(badge.title)
                        .font(Theme.Font.caption)
                        .foregroundStyle(earned ? Theme.textPrimary : Theme.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(earned ? Theme.accentSoft : Theme.surfaceRaised.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityLabel("\(badge.title). \(badge.detail) \(earned ? "Earned." : "Not yet.")")
            }
        }
    }
}
