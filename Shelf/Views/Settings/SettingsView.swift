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
                Section("Shelved apps") {
                    Button {
                        Task {
                            if screenTime.isAuthorized || (await screenTime.requestAuthorization()) {
                                showPicker = true
                            }
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

                Section("Stats") {
                    LabeledContent("Current streak", value: "\(appState.stats.streak) days")
                    LabeledContent("Longest streak", value: "\(appState.stats.longestStreak) days")
                    LabeledContent("Total shelved", value: appState.stats.totalFormatted)
                    LabeledContent("Sessions", value: "\(appState.stats.sessionsCompleted)")
                }

                Section("Plan") {
                    if store.isPro {
                        LabeledContent("Shelf Pro", value: "Active")
                        Button("Manage subscription") {
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        }
                    } else {
                        Button("Upgrade to Shelf Pro") { showPaywall = true }
                    }
                    Button("Restore purchases") { Task { await store.restore() } }
                }

                Section {
                    Link("Privacy policy", destination: URL(string: "https://shelfapp.example/privacy")!)
                    Link("Terms", destination: URL(string: "https://shelfapp.example/terms")!)
                    Link("Send feedback", destination: URL(string: "mailto:hello@shelfapp.example")!)
                } footer: {
                    Text("Shelf \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") · Everything stays on your phone.")
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
