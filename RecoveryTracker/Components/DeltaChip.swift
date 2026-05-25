import SwiftUI

struct DeltaChip: View {
    let value: Double
    var suffix: String = ""
    var goodUp: Bool = true

    private var isUp: Bool { value > 0 }
    private var isGood: Bool { goodUp ? isUp : !isUp }
    private var color: Color {
        guard value != 0 else { return .rtText3 }
        return isGood ? .rtTeal : .rtCoral
    }

    var body: some View {
        HStack(spacing: 2) {
            if value != 0 {
                Image(systemName: isUp ? "arrow.up" : "arrow.down")
                    .font(.system(size: 9, weight: .semibold))
            }
            Text(formattedValue)
                .font(.rtCaption)
                .kerning(-0.1)
        }
        .foregroundColor(color)
    }

    private var formattedValue: String {
        let abs = Swift.abs(value)
        let num = abs.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(abs))
            : String(format: "%.1f", abs)
        return "\(num)\(suffix)"
    }
}

#Preview {
    HStack(spacing: 16) {
        DeltaChip(value: 4, suffix: "ms", goodUp: true)
        DeltaChip(value: -2, suffix: "bpm", goodUp: false)
        DeltaChip(value: 0)
    }
    .padding()
}
