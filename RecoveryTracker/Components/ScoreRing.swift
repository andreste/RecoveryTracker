import SwiftUI

struct ScoreRing: View {
    let value: Int          // 0–100
    var size: CGFloat = 200
    var strokeWidth: CGFloat = 14
    var showLabel: Bool = true

    private var color: Color { ScoreHelpers.color(for: value) }
    private var label: (status: String, advice: String) { ScoreHelpers.label(for: value) }

    var body: some View {
        ZStack {
            // Track ring
            Circle()
                .stroke(Color.rtSeparator, lineWidth: strokeWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(value) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: value)

            // Center labels
            VStack(spacing: 6) {
                Text("\(value)")
                    .font(.rtHeroScore)
                    .kerning(-2)
                    .monospacedDigit()
                    .foregroundColor(.rtText)
                if showLabel {
                    Text(label.status.uppercased())
                        .font(.rtSection)
                        .kerning(1.2)
                        .foregroundColor(color)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 20) {
        ScoreRing(value: 91, size: 140, strokeWidth: 12)
        ScoreRing(value: 67, size: 140, strokeWidth: 12)
        ScoreRing(value: 42, size: 140, strokeWidth: 12)
    }
    .padding()
    .background(Color.rtBackground)
}
