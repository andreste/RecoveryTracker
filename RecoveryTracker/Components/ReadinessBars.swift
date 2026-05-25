import SwiftUI

struct ReadinessBar: Identifiable {
    let id = UUID()
    let day: String
    let score: Int
}

struct ReadinessBars: View {
    let data: [ReadinessBar]
    var height: CGFloat = 96

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, bar in
                let isToday = index == data.count - 1
                let barHeight = max(4, CGFloat(bar.score) / 100.0 * (height - 28))
                let color = ScoreHelpers.color(for: bar.score)
                VStack(spacing: 6) {
                    Text("\(bar.score)")
                        .font(.rtTabLabel)
                        .foregroundColor(.rtText3)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(height: barHeight)
                        .opacity(isToday ? 1.0 : 0.85)
                        .overlay(
                            isToday ?
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(color, lineWidth: 2)
                                .padding(-3)
                            : nil
                        )
                    Text(bar.day)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.rtText3)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: height)
    }
}

#Preview {
    Card {
        ReadinessBars(data: [
            ReadinessBar(day: "M", score: 62),
            ReadinessBar(day: "T", score: 71),
            ReadinessBar(day: "W", score: 58),
            ReadinessBar(day: "T", score: 74),
            ReadinessBar(day: "F", score: 81),
            ReadinessBar(day: "S", score: 67),
            ReadinessBar(day: "S", score: 78),
        ])
    }
    .padding()
    .background(Color.rtBackground)
}
