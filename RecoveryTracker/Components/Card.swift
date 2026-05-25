import SwiftUI

struct Card<Content: View>: View {
    var padding: CGFloat = RTSpacing.cardPad
    var radius: CGFloat = RTRadius.card
    @ViewBuilder let content: () -> Content
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content()
            .padding(padding)
            .background(Color.rtCard)
            .cornerRadius(radius)
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(0.04),
                radius: 1, x: 0, y: 1
            )
    }
}

#Preview {
    Card {
        Text("Card content")
            .font(.rtBody)
    }
    .padding()
    .background(Color.rtBackground)
}
