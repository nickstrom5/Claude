import SwiftUI
import UIKit

/// The screenshot people post. Square-ish so it works in Stories and feeds without cropping.
struct ShareCardView: View {
    let title: String
    let detail: String
    let streak: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "flipphone")
                    .foregroundStyle(Theme.accent)
                Text("Clam")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                if let streak, streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                        Text("\(streak)")
                    }
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.accent)
                }
            }
            Spacer()
            Text(title)
                .font(Theme.Font.display(34))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail)
                .font(Theme.Font.display(34))
                .foregroundStyle(Theme.accent)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Text("Fold it. Clam up.")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(24)
        .frame(width: 300, height: 300)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    /// Renders the card to a UIImage at 3x for sharing.
    @MainActor
    func render() -> UIImage? {
        let renderer = ImageRenderer(content: self.padding(24).background(Theme.background))
        renderer.scale = 3
        return renderer.uiImage
    }
}

/// UIKit share sheet bridge.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
