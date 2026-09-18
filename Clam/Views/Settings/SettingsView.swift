import FamilyControls
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var screenTime: ScreenTimeManager
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showPicker = false
    @State private var showPaywall = false

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

                Section {
                    Link("Privacy policy", destination: URL(string: "https://getclam.app/privacy.html")!)
                    Link("Terms", destination: URL(string: "https://getclam.app/terms.html")!)
                    Link("Send feedback", destination: URL(string: "mailto:support@getclam.app")!)
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
            .familyActivityPicker(isPresented: $showPicker, selection: $screenTime.selection)
            .sheet(isPresented: $showPaywall) {
                PaywallView(context: .home, onFinished: { showPaywall = false })
            }
        }
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
