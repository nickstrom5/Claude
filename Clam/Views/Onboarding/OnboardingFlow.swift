import SwiftUI

/// The belief sequence. Reorder by editing `Step.allCases` order; every screen is self-contained.
/// Rationale for each screen is in docs/02-onboarding-and-paywall.md.
struct OnboardingFlow: View {
    enum Step: Int, CaseIterable {
        case hook, hours, apps, triggers, reveal, permission, taste, result, paywall
    }

    @EnvironmentObject private var appState: AppState
    @State private var step: Step

    init(initialStep: Step = .hook) {
        _step = State(initialValue: initialStep)
    }

    private var stepsWithProgress: [Step] { Step.allCases.filter { $0 != .hook && $0 != .paywall } }

    var body: some View {
        VStack(spacing: 0) {
            if let index = stepsWithProgress.firstIndex(of: step) {
                OnboardingProgress(current: index, total: stepsWithProgress.count)
                    .padding(.horizontal, Theme.horizontalPadding)
                    .padding(.top, 12)
            }

            Group {
                switch step {
                case .hook:       HookScreen(onNext: advance)
                case .hours:      HoursScreen(onNext: advance)
                case .apps:       AppsScreen(onNext: advance)
                case .triggers:   TriggersScreen(onNext: advance)
                case .reveal:     RevealScreen(onNext: advance)
                case .permission: PermissionScreen(onNext: advance)
                case .taste:      TasteSessionScreen(onNext: advance)
                case .result:     TasteResultScreen(onNext: advance)
                case .paywall:    PaywallView(context: .onboarding, onFinished: finish)
                }
            }
            .id(step)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .opacity))
        }
        .animation(.easeInOut(duration: 0.3), value: step)
        .onAppear { Analytics.track(.onboardingStarted) }
        .onChange(of: step) { _, new in
            Analytics.track(.onboardingStep, ["step": new.rawValue, "name": String(describing: new)])
        }
    }

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return finish() }
        step = next
    }

    private func finish() {
        Analytics.track(.onboardingCompleted)
        appState.hasCompletedOnboarding = true
    }
}

/// Shared scaffold: title, optional subtitle, content, sticky CTA.
struct OnboardingScreen<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var cta: String = "Continue"
    var ctaEnabled: Bool = true
    var ctaLoading: Bool = false
    let onCTA: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle {
                        Text(subtitle)
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    content()
                        .padding(.top, 20)
                }
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.top, 36)
                .padding(.bottom, 24)
            }
            PrimaryButton(title: cta, isEnabled: ctaEnabled, isLoading: ctaLoading, action: onCTA)
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.bottom, 16)
        }
    }
}
