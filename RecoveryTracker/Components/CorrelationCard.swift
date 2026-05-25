import SwiftUI

struct CorrelationCard: View {
    let xLabel: String
    let yLabel: String
    let r: Double          // -1.0 to 1.0
    let strengthLabel: String
    let note: String

    private var isPositive: Bool { r > 0 }
    private var color: Color { isPositive ? .rtTeal : .rtCoral }
    private var filledSegments: Int { min(10, Int((abs(r) * 10).rounded())) }

    var body: some View {
        Card(padding: RTSpacing.rowPad, radius: RTRadius.card) {
            VStack(alignment: .leading, spacing: RTSpacing.sm) {
                // Header row
                HStack(alignment: .center, spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(xLabel) → \(yLabel)")
                            .font(.rtFootnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.rtText)
                            .kerning(-0.2)
                        HStack(spacing: 4) {
                            Text(strengthLabel)
                                .font(.rtCaption)
                                .fontWeight(.semibold)
                                .foregroundColor(color)
                            Text("· r = \(String(format: "%.2f", r))")
                                .font(.rtCaption)
                                .foregroundColor(.rtText3)
                        }
                    }
                }

                // Strength meter bar
                HStack(spacing: 2) {
                    ForEach(0..<10, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i < filledSegments ? color : Color.rtSeparator)
                            .frame(maxWidth: .infinity)
                            .frame(height: 4)
                    }
                }

                // Insight note
                Text(note)
                    .font(.rtFootnote)
                    .foregroundColor(.rtText2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        CorrelationCard(
            xLabel: "Sleep quality", yLabel: "Next-day HRV",
            r: 0.71, strengthLabel: "Strong positive",
            note: "Nights above 85% lead to a ~7ms HRV bump the next morning."
        )
        CorrelationCard(
            xLabel: "Training load (3-day)", yLabel: "Resting HR",
            r: 0.58, strengthLabel: "Moderate positive",
            note: "RHR climbs ~3 bpm when 3-day load exceeds 380 au."
        )
        CorrelationCard(
            xLabel: "Alcohol", yLabel: "Deep sleep",
            r: -0.64, strengthLabel: "Strong negative",
            note: "Logged drinks reduced deep sleep by 22 minutes on average."
        )
    }
    .padding()
    .background(Color.rtBackground)
}
