import SwiftUI

struct MetricTile: View {
    let icon: String         // SF Symbol name
    let label: String
    let value: String
    let unit: String
    let delta: Double
    var deltaSuffix: String = ""
    var goodUp: Bool = true
    let accent: Color

    var body: some View {
        Card(padding: RTSpacing.rowPad, radius: RTRadius.card) {
            VStack(alignment: .leading, spacing: RTSpacing.sm) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: RTRadius.badge)
                            .fill(accent.opacity(0.13))
                            .frame(width: 28, height: 28)
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(accent)
                    }
                    Spacer()
                    DeltaChip(value: delta, suffix: deltaSuffix, goodUp: goodUp)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.rtCaption)
                        .foregroundColor(.rtText3)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(value)
                            .font(.system(size: 26, weight: .bold))
                            .kerning(-0.8)
                            .monospacedDigit()
                            .foregroundColor(.rtText)
                        Text(unit)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.rtText3)
                    }
                }
            }
            .frame(minHeight: 80)
        }
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
        MetricTile(icon: "waveform.path.ecg", label: "HRV",        value: "68",  unit: "ms",  delta: 4,  deltaSuffix: "ms",  goodUp: true,  accent: .rtTeal)
        MetricTile(icon: "heart.fill",         label: "Resting HR", value: "52",  unit: "bpm", delta: -2, deltaSuffix: "bpm", goodUp: false, accent: .rtCoral)
        MetricTile(icon: "moon.fill",           label: "Sleep",      value: "84",  unit: "%",   delta: 3,  deltaSuffix: "%",   goodUp: true,  accent: .rtPurple)
        MetricTile(icon: "bolt.fill",           label: "Load",       value: "312", unit: "au",  delta: 18,                    goodUp: false, accent: .rtAmber)
    }
    .padding()
    .background(Color.rtBackground)
}
