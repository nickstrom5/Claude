import SwiftUI

struct PrimaryButton: View {
    let title: String
    var subtitle: String? = nil
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                VStack(spacing: 2) {
                    Text(title)
                        .font(Theme.Font.headline)
                    if let subtitle {
                        Text(subtitle)
                            .font(Theme.Font.caption)
                            .opacity(0.7)
                    }
                }
                .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(.black)
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(isEnabled ? Theme.accent : Theme.accent.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(PressScaleStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Theme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(PressScaleStyle())
    }
}

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
