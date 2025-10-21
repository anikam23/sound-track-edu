import SwiftUI

struct Theme {
    // Brand colors
    static let accent = Color(.sRGB, red: 0.16, green: 0.61, blue: 0.54, opacity: 1)
    static let beige  = Color(.sRGB, red: 0.98, green: 0.96, blue: 0.90, opacity: 1)

    // Surfaces
    // --- Pick ONE of these card values and comment out the others ---
    
    // Option A — slightly lighter (airy, subtle)
    // static let card = Color(.sRGB, red: 0.98, green: 0.96, blue: 0.91, opacity: 1.0)

    // Option B — slightly darker (adds more pop / contrast)
    // static let card = Color(.sRGB, red: 0.95, green: 0.93, blue: 0.87, opacity: 1.0)

    // Current / default (in-between) - matches beige better
    static let card = Color(.sRGB, red: 0.97, green: 0.95, blue: 0.90, opacity: 1.0)

    // Text
    static let primaryText: Color = .primary
    static let subtext: Color     = .secondary

    // Layout
    static let spacing: CGFloat   = 12

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

// MARK: - Color Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

