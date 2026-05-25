import Foundation

enum TimeFormatting {
    // Minutes → "Xh Ym" (e.g. 458 → "7h 38m")
    static func hoursMinutes(_ minutes: Int) -> String {
        "\(minutes / 60)h \(String(format: "%02d", minutes % 60))m"
    }

    // Seconds → clock duration: "54:12" under an hour, "1:08:21" over.
    static func clockDuration(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return "\(h):\(String(format: "%02d", m)):\(String(format: "%02d", s))"
        }
        return "\(m):\(String(format: "%02d", s))"
    }
}
