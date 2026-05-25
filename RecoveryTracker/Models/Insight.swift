import Foundation

// A generated daily insight shown on the Today screen.
struct Insight: Equatable {
    enum Sentiment: String, Codable {
        case positive, neutral, caution

        var label: String { rawValue.uppercased() }
    }

    let title: String
    let body: String
    let recommendation: String?
    let sentiment: Sentiment
}
