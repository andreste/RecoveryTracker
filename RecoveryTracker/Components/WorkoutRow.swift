import SwiftUI

enum RecoveryCost {
    case low, medium, high

    var label: String {
        switch self {
        case .low:    return "LOW"
        case .medium: return "MED"
        case .high:   return "HIGH"
        }
    }

    var color: Color {
        switch self {
        case .low:    return .rtTeal
        case .medium: return .rtAmber
        case .high:   return .rtCoral
        }
    }

    var background: Color {
        switch self {
        case .low:    return .rtTealSoft
        case .medium: return .rtAmberSoft
        case .high:   return .rtCoralSoft
        }
    }
}

struct WorkoutRowData: Identifiable {
    let id = UUID()
    let sport: Sport
    let title: String
    let day: String
    let duration: String
    let detail: String
    let cost: RecoveryCost
}

struct WorkoutRow: View {
    let workout: WorkoutRowData
    var showSeparator: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            // Sport tile
            ZStack {
                RoundedRectangle(cornerRadius: RTRadius.iconTile)
                    .fill(workout.sport.defaultColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                SportIconView(sport: workout.sport, size: 22)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.title)
                    .font(.rtSubhead)
                    .fontWeight(.semibold)
                    .foregroundColor(.rtText)
                    .kerning(-0.2)
                HStack(spacing: 4) {
                    Text(workout.day)
                        .font(.rtCaption)
                        .fontWeight(.semibold)
                        .foregroundColor(.rtText2)
                    Text("·").foregroundColor(.rtText4)
                    Text(workout.duration)
                        .font(.rtCaption)
                        .monospacedDigit()
                        .foregroundColor(.rtText3)
                    Text("·").foregroundColor(.rtText4)
                    Text(workout.detail)
                        .font(.rtCaption)
                        .foregroundColor(.rtText3)
                }
            }

            Spacer()

            // Recovery cost badge
            Text(workout.cost.label)
                .font(.system(size: 11, weight: .bold))
                .kerning(0.3)
                .foregroundColor(workout.cost.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(workout.cost.background)
                .cornerRadius(RTRadius.badge)
        }
        .padding(.horizontal, RTSpacing.cardPad)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if showSeparator {
                Color.rtSeparator
                    .frame(height: 0.5)
                    .padding(.leading, 72)
            }
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        WorkoutRow(workout: WorkoutRowData(sport: .run,  title: "Easy aerobic run",       day: "Today",     duration: "54:12",   detail: "8.2 km",  cost: .low))
        WorkoutRow(workout: WorkoutRowData(sport: .lift, title: "Lower body — strength",  day: "Yesterday", duration: "48:30",   detail: "5 sets",  cost: .medium))
        WorkoutRow(workout: WorkoutRowData(sport: .run,  title: "Tempo intervals",         day: "Fri",       duration: "1:08:21", detail: "12.4 km", cost: .high), showSeparator: false)
    }
    .background(Color.rtCard)
    .cornerRadius(RTRadius.card)
    .padding()
    .background(Color.rtBackground)
}
