import SwiftUI

enum Theme {
    static let cornerRadius: CGFloat = 16
}

extension Color {
    /// Warm coral/terracotta — #E07856
    static let primaryAccent = Color(red: 0.878, green: 0.471, blue: 0.337)
    /// Deeper terracotta for active/recording states — #B84F35
    static let accentDeep = Color(red: 0.722, green: 0.310, blue: 0.208)
    /// Warm off-white/cream app background — #FAF4EE
    static let appBackground = Color(red: 0.980, green: 0.957, blue: 0.933)
    static let cardBackground = Color.white
    /// Dark warm brown — #3D2C24
    static let textPrimary = Color(red: 0.239, green: 0.173, blue: 0.141)
    /// Muted warm gray — #9C8A80
    static let textSecondary = Color(red: 0.612, green: 0.541, blue: 0.502)
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
