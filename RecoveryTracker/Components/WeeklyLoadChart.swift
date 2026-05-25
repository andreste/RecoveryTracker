import SwiftUI

/// A Mon–Sun training-load bar chart. Each bar is colored by load bucket
/// (> 400 coral, > 250 amber, else teal); a rest day (load 0) renders as a
/// dashed outline placeholder. Day letters sit under each bar. Style mirrors
/// `ReadinessBars`.
struct WeeklyLoadChart: View {
    let data: [DayLoad]
    var height: CGFloat = 120

    // Scale bars to the busiest day so the chart fills the available height.
    private var maxLoad: Int { max(data.map(\.load).max() ?? 0, 1) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(data) { day in
                VStack(spacing: 6) {
                    bar(for: day)
                    Text(day.day)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.rtText3)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: height)
    }

    @ViewBuilder
    private func bar(for day: DayLoad) -> some View {
        let area = height - 24
        if day.isRest {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.rtText4, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                .frame(height: 6)
                .frame(maxHeight: area, alignment: .bottom)
        } else {
            let barHeight = max(6, CGFloat(day.load) / CGFloat(maxLoad) * area)
            RoundedRectangle(cornerRadius: 6)
                .fill(TrainingViewModel.loadLevel(for: day.load).color)
                .frame(height: barHeight)
        }
    }
}

#Preview {
    Card {
        WeeklyLoadChart(data: [
            DayLoad(day: "M", load: 240),
            DayLoad(day: "T", load: 0),
            DayLoad(day: "W", load: 310),
            DayLoad(day: "T", load: 180),
            DayLoad(day: "F", load: 460),
            DayLoad(day: "S", load: 0),
            DayLoad(day: "S", load: 520),
        ])
    }
    .padding()
    .background(Color.rtBackground)
}
