import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel: TodayViewModel

    init(health: HealthDataProviding = HealthKitService()) {
        _viewModel = StateObject(wrappedValue: TodayViewModel(health: health))
    }

    private var score: ReadinessScore { viewModel.score }
    private var scoreColor: Color { ScoreHelpers.color(for: score.value) }

    private let metricColumns = [
        GridItem(.flexible(), spacing: RTSpacing.gap),
        GridItem(.flexible(), spacing: RTSpacing.gap)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, RTSpacing.titlePad)
                        .padding(.top, RTSpacing.sm)

                    scoreSection
                        .padding(.top, RTSpacing.lg)

                    metricGrid
                        .padding(.horizontal, RTSpacing.cardPad)
                        .padding(.top, RTSpacing.lg)

                    readinessCard
                        .padding(.horizontal, RTSpacing.cardPad)
                        .padding(.top, RTSpacing.md)

                    insightCard
                        .padding(.horizontal, RTSpacing.cardPad)
                        .padding(.top, RTSpacing.md)

                    quickActions
                        .padding(.horizontal, RTSpacing.cardPad)
                        .padding(.top, RTSpacing.md)
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
                Text("Today")
                    .font(.rtLargeTitle)
                    .foregroundColor(.rtText)
                Text(viewModel.dateSubtitle)
                    .font(.rtSubhead)
                    .foregroundColor(.rtText3)
            }
            Spacer()
            avatar
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(Color.rtTeal.opacity(0.15))
                .frame(width: 40, height: 40)
            Text("JS")
                .font(.rtCaption)
                .foregroundColor(.rtTeal)
        }
    }

    // MARK: - Score ring + status

    private var scoreSection: some View {
        VStack(spacing: RTSpacing.md) {
            ScoreRing(value: score.value, size: 180, strokeWidth: 14, showLabel: true)

            VStack(spacing: RTSpacing.xs) {
                Text("\(score.status) — \(score.advice)")
                    .font(.rtHeadline)
                    .foregroundColor(.rtText)

                HStack(spacing: 4) {
                    Text("Score is")
                        .foregroundColor(.rtText3)
                    Text("\(score.baselineDeltaString)")
                        .foregroundColor(scoreColor)
                    Text("vs 30-day baseline")
                        .foregroundColor(.rtText3)
                }
                .font(.rtFootnote)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Metric grid

    private var metricGrid: some View {
        LazyVGrid(columns: metricColumns, spacing: RTSpacing.gap) {
            ForEach(viewModel.metrics.all) { metric in
                let style = MetricStyle.style(for: metric.kind)
                MetricTile(
                    icon: style.icon,
                    label: metric.kind.displayName,
                    value: Self.valueString(metric.value),
                    unit: metric.unit,
                    delta: metric.delta.value,
                    deltaSuffix: style.deltaSuffix,
                    goodUp: metric.delta.goodUp,
                    accent: style.accent
                )
            }
        }
    }

    // MARK: - 7-day readiness chart

    private var readinessCard: some View {
        Card {
            VStack(alignment: .leading, spacing: RTSpacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    Text("7-DAY READINESS")
                        .font(.rtSection)
                        .kerning(0.8)
                        .foregroundColor(.rtText3)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Avg \(averageReadiness)")
                            .font(.rtCaption)
                            .foregroundColor(.rtText)
                        DeltaChip(value: Double(score.value - averageReadiness), goodUp: true)
                    }
                }

                ReadinessBars(data: readinessBars)

                legend
            }
        }
    }

    private var legend: some View {
        HStack(spacing: RTSpacing.md) {
            legendItem(color: .rtTeal, label: "Good")
            legendItem(color: .rtAmber, label: "Moderate")
            legendItem(color: .rtCoral, label: "Poor")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: - Daily insight

    private var insightCard: some View {
        let sentimentColor = Self.color(for: viewModel.insight.sentiment)
        return Card {
            VStack(alignment: .leading, spacing: RTSpacing.sm) {
                HStack {
                    Text("DAILY INSIGHT")
                        .font(.rtSection)
                        .kerning(0.8)
                        .foregroundColor(.rtText3)
                    Spacer()
                    Text(viewModel.insight.sentiment.label)
                        .font(.system(size: 10, weight: .bold))
                        .kerning(0.4)
                        .foregroundColor(sentimentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(sentimentColor.opacity(0.13))
                        .cornerRadius(RTRadius.badge)
                }

                Text(viewModel.insight.body)
                    .font(.rtBody)
                    .foregroundColor(.rtText)
                    .fixedSize(horizontal: false, vertical: true)

                if let recommendation = viewModel.insight.recommendation {
                    Text(recommendation)
                        .font(.rtSubhead)
                        .foregroundColor(.rtText2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [sentimentColor.opacity(0.10), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(RTRadius.card)
        )
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        HStack(spacing: RTSpacing.gap) {
            quickAction(icon: "figure.run", label: "Log workout", accent: .rtTeal)
            quickAction(icon: "moon.fill", label: "Log sleep", accent: .rtPurple)
        }
    }

    private func quickAction(icon: String, label: String, accent: Color) -> some View {
        // Visual affordance only — logging isn't part of this ticket.
        Button(action: {}) {
            Card(radius: RTRadius.quickAction) {
                HStack(spacing: RTSpacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(accent)
                    Text(label)
                        .font(.rtBody)
                        .foregroundColor(.rtText)
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Derived view data

    private var readinessBars: [ReadinessBar] {
        viewModel.history.map {
            ReadinessBar(day: Self.weekdayLetter(for: $0.date), score: $0.score)
        }
    }

    private var averageReadiness: Int {
        let scores = viewModel.history.map(\.score)
        guard !scores.isEmpty else { return score.value }
        return Int((Double(scores.reduce(0, +)) / Double(scores.count)).rounded())
    }

    // MARK: - Formatting helpers

    private static func valueString(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }

    private static func weekdayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE" // single-letter weekday
        return formatter.string(from: date)
    }

    private static func color(for sentiment: Insight.Sentiment) -> Color {
        switch sentiment {
        case .positive: return .rtTeal
        case .neutral:  return .rtAmber
        case .caution:  return .rtCoral
        }
    }
}

// Per-metric presentation: SF Symbol, accent color, and delta unit suffix.
private enum MetricStyle {
    static func style(for kind: Metric.Kind) -> (icon: String, accent: Color, deltaSuffix: String) {
        switch kind {
        case .hrv:          return ("waveform.path.ecg", .rtTeal,   "ms")
        case .restingHR:    return ("heart.fill",        .rtCoral,  "bpm")
        case .sleepQuality: return ("moon.fill",         .rtPurple, "%")
        case .trainingLoad: return ("bolt.fill",         .rtAmber,  "")
        }
    }
}

#Preview("Light") {
    TodayView()
}

#Preview("Dark") {
    TodayView()
        .preferredColorScheme(.dark)
}
