import SwiftUI

enum Sport: String, CaseIterable {
    case run   = "run"
    case ride  = "ride"
    case swim  = "swim"
    case lift  = "lift"
    case yoga  = "yoga"

    var symbolName: String {
        switch self {
        case .run:  return "figure.run"
        case .ride: return "bicycle"
        case .swim: return "figure.pool.swim"
        case .lift: return "dumbbell.fill"
        case .yoga: return "figure.mind.and.body"
        }
    }

    var defaultColor: Color {
        switch self {
        case .run:  return .rtTeal
        case .ride: return .rtBlue
        case .swim: return .rtPurple
        case .lift: return .rtAmber
        case .yoga: return .rtPurple
        }
    }

    var displayName: String {
        switch self {
        case .run:  return "Running"
        case .ride: return "Cycling"
        case .swim: return "Swimming"
        case .lift: return "Strength"
        case .yoga: return "Yoga"
        }
    }

    init?(key: String) { self.init(rawValue: key) }
}

struct SportIconView: View {
    let sport: Sport
    var size: CGFloat = 22
    var color: Color? = nil

    var body: some View {
        Image(systemName: sport.symbolName)
            .font(.system(size: size, weight: .semibold))
            .foregroundColor(color ?? sport.defaultColor)
    }
}

#Preview {
    HStack(spacing: 20) {
        ForEach(Sport.allCases, id: \.rawValue) { sport in
            VStack(spacing: 8) {
                SportIconView(sport: sport, size: 26)
                Text(sport.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.rtText3)
            }
        }
    }
    .padding()
}
