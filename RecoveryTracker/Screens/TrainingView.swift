import SwiftUI

struct TrainingView: View {
    @StateObject private var viewModel: TrainingViewModel

    // Number of recent workouts shown in the list (the rest stay in the count).
    private let visibleCount = 6

    init(health: HealthDataProviding = HealthKitService()) {
        _viewModel = StateObject(wrappedValue: TrainingViewModel(health: health))
    }

    private var visibleWorkouts: [WorkoutRowData] {
        Array(viewModel.workouts.prefix(visibleCount))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    weeklyLoadCard
                        .padding(.horizontal, RTSpacing.cardPad)
                        .padding(.top, RTSpacing.sm)

                    SectionLabel(text: "Recent · \(visibleWorkouts.count) of \(viewModel.workouts.count)")

                    recentCard
                        .padding(.horizontal, RTSpacing.cardPad)
                        .padding(.bottom, RTSpacing.lg)
                }
            }
            .background(Color.rtBackground)
            .navigationTitle("Training")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { addButton }
            }
            .safeAreaInset(edge: .top, spacing: 0) { subtitle }
        }
        .task { await viewModel.load() }
    }

    // MARK: - Nav extras

    private var subtitle: some View {
        Text(viewModel.weekSubtitle)
            .font(.rtSubhead)
            .foregroundColor(.rtText3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, RTSpacing.titlePad)
            .padding(.bottom, RTSpacing.xs)
    }

    private var addButton: some View {
        // Visual affordance only — adding workouts isn't part of this ticket.
        Image(systemName: "plus")
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 30, height: 30)
            .background(Circle().fill(Color.rtTeal))
    }

    // MARK: - Weekly load card

    private var weeklyLoadCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("WEEKLY LOAD")
                    .font(.rtSection)
                    .kerning(0.8)
                    .foregroundColor(.rtText3)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(viewModel.totalLoadString)
                                .font(.rtHeroNumeric)
                                .monospacedDigit()
                                .foregroundColor(.rtText)
                            Text("au")
                                .font(.rtSubhead)
                                .foregroundColor(.rtText3)
                        }
                        Text("This week")
                            .font(.rtCaption)
                            .foregroundColor(.rtText3)
                    }

                    Spacer()

                    Text(viewModel.status.label)
                        .font(.system(size: 11, weight: .bold))
                        .kerning(0.4)
                        .foregroundColor(viewModel.status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(viewModel.status.color.opacity(0.12))
                        .cornerRadius(RTRadius.pill)
                }

                WeeklyLoadChart(data: viewModel.weeklyLoad)
            }
        }
    }

    // MARK: - Recent workouts card

    private var recentCard: some View {
        Card(padding: 0) {
            VStack(spacing: 0) {
                ForEach(Array(visibleWorkouts.enumerated()), id: \.element.id) { index, workout in
                    WorkoutRow(workout: workout,
                               showSeparator: index < visibleWorkouts.count - 1)
                }
            }
        }
    }
}

#Preview("Light") {
    TrainingView()
}

#Preview("Dark") {
    TrainingView()
        .preferredColorScheme(.dark)
}
