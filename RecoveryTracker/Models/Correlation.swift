import Foundation

// An auto-detected relationship between two metrics, shown on Trends.
struct Correlation: Identifiable, Equatable {
    let id: UUID
    let xLabel: String
    let yLabel: String
    let r: Double
    let note: String

    init(id: UUID = UUID(), xLabel: String, yLabel: String, r: Double, note: String) {
        self.id = id
        self.xLabel = xLabel
        self.yLabel = yLabel
        self.r = r
        self.note = note
    }

    var isPositive: Bool { r > 0 }

    // 0–10 filled segments for the strength meter.
    var filledSegments: Int { min(10, Int((abs(r) * 10).rounded())) }

    var strengthLabel: String {
        let magnitude = abs(r)
        let descriptor: String
        if magnitude >= 0.6 { descriptor = "Strong" }
        else if magnitude >= 0.4 { descriptor = "Moderate" }
        else if magnitude >= 0.2 { descriptor = "Weak" }
        else { descriptor = "Negligible" }
        return "\(descriptor) \(isPositive ? "positive" : "negative")"
    }
}
