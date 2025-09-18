import SwiftUI

struct Theme {
    // Brand colors
    static let accent = Color(.sRGB, red: 0.16, green: 0.61, blue: 0.54, opacity: 1)
    static let beige  = Color(.sRGB, red: 0.98, green: 0.96, blue: 0.90, opacity: 1)

    // Surfaces
    static let background: Color = Color(UIColor.systemBackground)
    static let card: Color        = Color(UIColor.secondarySystemBackground) // ← added

    // Text
    static let primaryText: Color = .primary
    static let subtext: Color     = .secondary                                // ← added earlier

    // Layout
    static let spacing: CGFloat   = 12                                        // ← added earlier

    // Buttons
    struct FilledButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.accent.opacity(configuration.isPressed ? 0.85 : 1))
                .foregroundStyle(.white)
                .clipShape(Capsule())
        }
    }

    struct BorderedCapsuleStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .strokeBorder(Color.secondary.opacity(configuration.isPressed ? 0.6 : 0.3), lineWidth: 1)
                )
        }
    }
}
