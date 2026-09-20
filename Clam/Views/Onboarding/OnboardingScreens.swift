import FamilyControls
import SwiftUI

// MARK: - 1. Hook

struct HookScreen: View {
    let onNext: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("The average person will spend")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.textSecondary)
            Text("17 years")
                .font(Theme.Font.display(88))
                .foregroundStyle(Theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)   // fits on a 375pt-wide SE without wrapping
                .padding(.vertical, -6)
            Text("of their adult life on a screen.")
                .font(Theme.Font.title)
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            PrimaryButton(title: "Not me", action: onNext)
            Text("Clam locks the apps that steal your time. One tap. One fold.")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, Theme.horizontalPadding)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { appeared = true } }
    }
}

// MARK: - 2. Hours per day

struct HoursScreen: View {
    @EnvironmentObject private var appState: AppState
    let onNext: () -> Void

    var body: some View {
        OnboardingScreen(
            title: "Honestly, how many hours a day are you on your phone?",
            subtitle: "Check Settings → Screen Time if you're not sure. Most people guess low.",
            onCTA: onNext
        ) {
            VStack(spacing: 24) {
                Text(String(format: "%.1f h", appState.answers.hoursPerDay))
                    .font(Theme.Font.display(64))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .contentTransition(.numericText())
                Slider(value: $appState.answers.hoursPerDay, in: 1...12, step: 0.5)
                    .tint(Theme.accent)
                HStack {
                    Text("1h").font(Theme.Font.caption).foregroundStyle(Theme.textTertiary)
                    Spacer()
                    Text("Average: 4.5h").font(Theme.Font.caption).foregroundStyle(Theme.textTertiary)
                    Spacer()
                    Text("12h").font(Theme.Font.caption).foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(.top, 20)
        }
    }
}

// MARK: - 3. Apps (this is also the real configuration step)

struct AppsScreen: View {
    @EnvironmentObject private var screenTime: ScreenTimeManager
    let onNext: () -> Void
    @State private var showPicker = false
    @State private var showDeniedAlert = false

    var body: some View {
        OnboardingScreen(
            title: "Which apps steal the most from you?",
            subtitle: "These are the ones Clam will lock during a session. You can change them any time.",
            ctaEnabled: screenTime.hasSelection,
            onCTA: {
                Analytics.track(.appsSelected, ["count": screenTime.selectedCount])
                onNext()
            }
        ) {
            VStack(spacing: 16) {
                Button {
                    if ScreenTimeManager.isSimulator {
                        // No real picker in the simulator; pretend four apps were chosen.
                        screenTime.simulatedSelectionCount = screenTime.hasSelection ? 0 : 4
                        return
                    }
                    Task {
                        var allowed = screenTime.isAuthorized
                        if !allowed { allowed = await screenTime.requestAuthorization() }
                        if allowed {
                            showPicker = true
                        } else {
                            showDeniedAlert = true
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: screenTime.hasSelection ? "checkmark.circle.fill" : "plus.circle.fill")
                            .foregroundStyle(screenTime.hasSelection ? Theme.success : Theme.accent)
                        Text(screenTime.hasSelection
                             ? "\(screenTime.selectedCount) selected. Tap to change."
                             : "Choose apps")
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.textTertiary)
                    }
                    .font(Theme.Font.headline)
                    .padding(18)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(PressScaleStyle())

                Text(ScreenTimeManager.isSimulator
                     ? "Simulator: tapping above pretends 4 apps were chosen. Real blocking needs a device."
                     : "Popular picks: Instagram, TikTok, X, YouTube, Reddit, Safari.")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .familyActivityPicker(isPresented: $showPicker, selection: $screenTime.selection)
        .alert("Screen Time access needed", isPresented: $showDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("Clam can only lock apps if iOS lets it. Allow Screen Time access for Clam in Settings.")
        }
    }
}

// MARK: - 4. Triggers

struct TriggersScreen: View {
    @EnvironmentObject private var appState: AppState
    let onNext: () -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        OnboardingScreen(
            title: "When do you reach for it without thinking?",
            subtitle: "Pick all that apply.",
            ctaEnabled: !appState.answers.triggers.isEmpty,
            onCTA: onNext
        ) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(OnboardingAnswers.Trigger.allCases) { trigger in
                    let selected = appState.answers.triggers.contains(trigger)
                    Button {
                        if selected { appState.answers.triggers.remove(trigger) }
                        else { appState.answers.triggers.insert(trigger) }
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(systemName: trigger.symbol)
                                .font(.title2)
                                .foregroundStyle(selected ? Theme.accent : Theme.textSecondary)
                            Text(trigger.label)
                                .font(Theme.Font.headline)
                                .foregroundStyle(Theme.textPrimary)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(selected ? Theme.accentSoft : Theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(selected ? Theme.accent : .clear, lineWidth: 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(PressScaleStyle())
                }
            }
        }
    }
}

// MARK: - 5. Reveal

struct RevealScreen: View {
    @EnvironmentObject private var appState: AppState
    let onNext: () -> Void
    @State private var shownDays = 0
    @State private var showBack = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("At \(String(format: "%.1f", appState.answers.hoursPerDay)) hours a day, that's")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(shownDays)")
                    .font(Theme.Font.display(96))
                    .foregroundStyle(Theme.danger)
                    .contentTransition(.numericText())
                Text("days")
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.textPrimary)
            }
            Text("every year. Full 24-hour days.")
                .font(Theme.Font.title)
                .foregroundStyle(Theme.textPrimary)

            if showBack {
                VStack(alignment: .leading, spacing: 6) {
                    Divider().overlay(Theme.surfaceRaised).padding(.vertical, 20)
                    Text("People who lock their apps consistently cut that by about a third.")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(appState.answers.daysBackPerYear)")
                            .font(Theme.Font.display(56))
                            .foregroundStyle(Theme.success)
                        Text("days back. Every year.")
                            .font(Theme.Font.headline)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            Spacer()
            PrimaryButton(title: "I want those days back", isEnabled: showBack, action: onNext)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, Theme.horizontalPadding)
        .task {
            let target = appState.answers.daysPerYear
            if ScreenshotMode.isActive {
                shownDays = target
                showBack = true
                return
            }
            for i in stride(from: 0, through: target, by: max(1, target / 30)) {
                withAnimation(.easeOut(duration: 0.05)) { shownDays = i }
                try? await Task.sleep(nanoseconds: 35_000_000)
            }
            withAnimation { shownDays = target }
            try? await Task.sleep(nanoseconds: 700_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showBack = true }
        }
    }
}

// MARK: - 6. Permission (only shown if not already granted during app picking)

struct PermissionScreen: View {
    @EnvironmentObject private var screenTime: ScreenTimeManager
    let onNext: () -> Void
    @State private var requesting = false

    var body: some View {
        OnboardingScreen(
            title: screenTime.isAuthorized ? "Clam is allowed to lock your apps." : "Let Clam lock the apps you picked.",
            subtitle: screenTime.isAuthorized
                ? "Everything stays on your phone. Clam never sees what you do in them."
                : "iOS will ask for Screen Time access. Clam uses it only to lock the apps you chose during a session. Nothing leaves your phone.",
            cta: screenTime.isAuthorized ? "Continue" : "Allow Screen Time",
            ctaLoading: requesting,
            onCTA: {
                if screenTime.isAuthorized { onNext(); return }
                requesting = true
                Task {
                    let ok = await screenTime.requestAuthorization()
                    requesting = false
                    if ok { onNext() }
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                PermissionRow(symbol: "lock.fill", text: "Locks only the apps you chose, only during a session.")
                PermissionRow(symbol: "eye.slash.fill", text: "Can't read your messages, browsing or anything inside apps.")
                PermissionRow(symbol: "iphone", text: "Runs entirely on this phone. No account, no cloud.")
            }
        }
        .onAppear { screenTime.refreshAuthorization() }
    }
}

private struct PermissionRow: View {
    let symbol: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
            Text(text)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - 7. Taste session (the product, before the paywall)

struct TasteSessionScreen: View {
    @EnvironmentObject private var sessions: SessionManager
    @EnvironmentObject private var screenTime: ScreenTimeManager
    let onNext: () -> Void

    private let tasteSeconds = 60

    var body: some View {
        VStack(spacing: 0) {
            if let session = sessions.active {
                VStack(spacing: 28) {
                    Spacer()
                    CountdownRing(start: session.start, end: session.plannedEnd)
                        .frame(width: 260, height: 260)
                    VStack(spacing: 8) {
                        Text("Your apps are locked. For real.")
                            .font(Theme.Font.title)
                            .foregroundStyle(Theme.textPrimary)
                        Text(ScreenTimeManager.isSimulator
                             ? "Simulator: lock the device (⌘L) to see the Live Activity.\nApp blocking only works on a real iPhone."
                             : "Lock your phone and look at the lock screen.\nThen try opening one of the apps you picked.")
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .padding(.horizontal, Theme.horizontalPadding)
            } else {
                OnboardingScreen(
                    title: "Let's do one right now.",
                    subtitle: "A 1-minute session. \(screenTime.selectedCount) app\(screenTime.selectedCount == 1 ? "" : "s") get locked, a timer appears on your lock screen, and you get to see the block screen for yourself.",
                    cta: "Clam up for 1 minute",
                    onCTA: { sessions.start(minutes: 1, isTaste: true) }
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        StepRow(number: 1, text: "Tap the button.")
                        StepRow(number: 2, text: "Lock your phone (or fold it).")
                        StepRow(number: 3, text: "Try to open Instagram. Go on.")
                    }
                }
            }
        }
        .onChange(of: sessions.lastFinished) { _, finished in
            if finished?.isTaste == true { onNext() }
        }
    }
}

private struct StepRow: View {
    let number: Int
    let text: String
    var body: some View {
        HStack(spacing: 14) {
            Text("\(number)")
                .font(Theme.Font.headline)
                .foregroundStyle(.black)
                .frame(width: 30, height: 30)
                .background(Theme.accent)
                .clipShape(Circle())
            Text(text)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.textPrimary)
        }
    }
}

// MARK: - 8. Result

struct TasteResultScreen: View {
    @EnvironmentObject private var appState: AppState
    let onNext: () -> Void
    @State private var showShare = false

    var body: some View {
        GeometryReader { geo in
        // The card is a fixed 300pt square; shrink its layout footprint (not just its pixels)
        // so the copy above it never gets squeezed to one line on a 4.7" phone.
        let cardScale = min(0.9, max(0.55, (geo.size.height - 400) / 300))
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.success)
                .padding(.bottom, 20)
            Text("You just clammed up your phone.")
                .font(Theme.Font.title)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("That was 1 minute. Do it daily and you get **\(appState.answers.daysBackPerYear) days a year** back. That's the whole trick.")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
                .padding(.horizontal, 8)

            ShareCardView(title: "I clammed up my phone", detail: "for the first time", streak: nil)
                .scaleEffect(cardScale)
                .frame(width: 300 * cardScale, height: 300 * cardScale)
                .padding(.top, 28)

            Spacer()
            PrimaryButton(title: "Keep going", action: onNext)
            Button {
                Analytics.track(.shareTapped, ["from": "onboarding"])
                showShare = true
            } label: {
                Text("Share this")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(height: 44)
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Theme.horizontalPadding)
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [ShareCardView(title: "I clammed up my phone", detail: "for the first time", streak: nil).render()].compactMap { $0 })
        }
    }
}
