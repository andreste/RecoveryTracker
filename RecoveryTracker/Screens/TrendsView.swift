import SwiftUI

struct TrendsView: View {
    @StateObject private var viewModel: TrendsViewModel

    init(health: HealthDataProviding = HealthKitService()) {
        _viewModel = StateObject(wrappedValue: TrendsViewModel(health: health))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, RTSpacing.titlePad)
                        .padding(.top, RTSpacing.sm)

                    chartCard
                        .padding(.horizontal, RTSpacing.cardPad)
                        .padding(.top, RTSpacing.lg)

                    SectionLabel(text: "Sleep · last 7 days")
                    sleepCard
                        .padding(.horizontal, RTSpacing.cardPad)

                    SectionLabel(text: "Correlations · auto-detected")
                    correlations
                        .padding(.horizontal, RTSpacing.cardPad)
                        .padding(.bottom, RTSpacing.lg)
                }
            }
            .background(Color.rtBackground)
            .navigationBarHidden(true)
        }
        .task { await viewModel.load() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Trends")
                    .font(.rtLargeTitle)
                    .foregroundColor(.rtText)
                Text("Last 28 days")
                    .font(.rtSubhead)
                    .foregroundColor(.rtText3)
            }
            Spacer()
            rangePill
        }
    }

    // Visual-only range selector affordance.
    private var rangePill: some View {
        Text("4W")
            .font(.rtCaption)
            .foregroundColor(.rtText)
            .padding(.horizontal, RTSpacing.md)
            .padding(.vertical, RTSpacing.sm)
            .background(Color.rtCard)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.rtSeparator, lineWidth: 1))
    }

    // MARK: - Dual-line chart card

    private var chartCard: some View {
        Card {
            VStack(alignment: .leading, spacing: RTSpacing.md) {
                HStack(alignment: .top) {
                    Text("HRV VS TRAINING LOAD")
                        .font(.rtSection)
                        .kerning(0.8)
                        .foregroundColor(.rtText3)
                    Spacer()
                    legend
                }

                HStack(alignment: .firstTextBaseline, spacing: RTSpacing.lg) {
                    bigStat(value: Self.intString(viewModel.hrvAverage), unit: "ms avg",
                            color: .rtTeal)
                    bigStat(value: Self.intString(viewModel.loadAverage), unit: "au avg",
                            color: .rtAmber)
                }

                DualLineChart(hrv: viewModel.hrvSeries, load: viewModel.loadSeries)

                weekAxis
            }
        }
    }

    private func bigStat(value: String, unit: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: RTSpacing.xs) {
            Text(value)
                .font(.rtTitle2)
                .monospacedDigit()
                .foregroundColor(color)
            Text(unit)
                .font(.rtCaption)
                .foregroundColor(.rtText3)
        }
    }

    private var legend: some View {
        HStack(spacing: RTSpacing.md) {
            legendItem(color: .rtTeal, label: "HRV")
            legendItem(color: .rtAmber, label: "Load")
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: RTSpacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.rtTabLabel)
                .foregroundColor(.rtText3)
        }
    }

    private var weekAxis: some View {
        HStack {
            ForEach(Array(Self.weekMarkers.enumerated()), id: \.offset) { index, label in
                Text(label)
                    .font(.rtTabLabel)
                    .foregroundColor(.rtText3)
                if index < Self.weekMarkers.count - 1 { Spacer() }
            }
        }
    }

    // MARK: - Sleep breakdown

    private var sleepCard: some View {
        Card {
            VStack(alignment: .leading, spacing: RTSpacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    Text(TimeFormatting.hoursMinutes(viewModel.sleep.totalInBedMinutes))
                        .font(.rtHeroNumeric)
                        .monospacedDigit()
                        .foregroundColor(.rtText)
                    Text("avg time in bed")
                        .font(.rtCaption)
                        .foregroundColor(.rtText3)
                    Spacer()
                    DeltaChip(value: Double(viewModel.sleep.asleepMinutes - viewModel.sleep.totalInBedMinutes),
                              suffix: "m", goodUp: true)
                }

                stackedBar

                VStack(spacing: RTSpacing.sm) {
                    ForEach(SleepBreakdown.Stage.allCases, id: \.self) { stage in
                        stageRow(stage)
                    }
                }
            }
        }
    }

    private var stackedBar: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(SleepBreakdown.Stage.allCases, id: \.self) { stage in
                    let total = max(viewModel.sleep.totalInBedMinutes, 1)
                    let fraction = CGFloat(viewModel.sleep.minutes(for: stage)) / CGFloat(total)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Self.color(for: stage))
                        .frame(width: max(0, geo.size.width * fraction - 2))
                }
            }
        }
        .frame(height: 12)
    }

    private func stageRow(_ stage: SleepBreakdown.Stage) -> some View {
        HStack(spacing: RTSpacing.sm) {
            Circle()
                .fill(Self.color(for: stage))
                .frame(width: 8, height: 8)
            Text(stage.displayName)
                .font(.rtBody)
                .foregroundColor(.rtText)
            Spacer()
            Text(TimeFormatting.hoursMinutes(viewModel.sleep.minutes(for: stage)))
                .font(.rtFootnote)
                .monospacedDigit()
                .foregroundColor(.rtText2)
            Text("\(viewModel.sleep.percentage(for: stage))%")
                .font(.rtCaption)
                .monospacedDigit()
                .foregroundColor(.rtText3)
                .frame(width: 38, alignment: .trailing)
        }
    }

    // MARK: - Correlations

    private var correlations: some View {
        VStack(spacing: RTSpacing.gap) {
            ForEach(viewModel.correlations) { correlation in
                CorrelationCard(
                    xLabel: correlation.xLabel,
                    yLabel: correlation.yLabel,
                    r: correlation.r,
                    strengthLabel: correlation.strengthLabel,
                    note: correlation.note
                )
            }
        }
    }

    // MARK: - Helpers

    private static func intString(_ value: Double) -> String {
        String(Int(value.rounded()))
    }

    private static func color(for stage: SleepBreakdown.Stage) -> Color {
        switch stage {
        case .deep:  return .rtBlue
        case .rem:   return .rtPurple
        case .core:  return .rtTeal
        case .awake: return .rtText4
        }
    }

    // x-axis week markers: 4 weekly ticks ending at "Today".
    private static var weekMarkers: [String] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let offsets = [21, 14, 7]
        var labels = offsets.map { offset -> String in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            return formatter.string(from: date)
        }
        labels.append("Today")
        return labels
    }
}

#Preview("Light") {
    TrendsView()
}

#Preview("Dark") {
    TrendsView()
        .preferredColorScheme(.dark)
}
