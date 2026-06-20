import Foundation

public struct UsageFormatter: Sendable {
    private let now: Date

    public init(now: Date = Date()) {
        self.now = now
    }

    public func render(_ snapshot: RateLimitSnapshot, stale: Bool = false) -> String {
        let selected = snapshot.selectedWindows()
        var rows = [
            row(label: "5小时", window: selected.fiveHour),
            row(label: "本周", window: selected.weekly),
        ]
        if stale {
            rows[rows.count - 1] += " ·"
        }
        return rows.joined(separator: "\n")
    }

    private func row(label: String, window: RateLimitWindow?) -> String {
        guard let window, let usedPercent = window.usedPercent, usedPercent.isFinite else {
            return "\(label)  ▱▱▱▱▱ --"
        }

        let remaining = min(100, max(0, 100 - usedPercent))
        let filledCount = min(5, max(0, Int((remaining / 20).rounded())))
        let bar = String(repeating: "▰", count: filledCount)
            + String(repeating: "▱", count: 5 - filledCount)
        let percentage = Int(remaining.rounded())
        let reset = resetDescription(window.resetsAt)
        return "\(label) \(bar) \(percentage)%\(reset.map { "  \($0)" } ?? "")"
    }

    private func resetDescription(_ timestamp: TimeInterval?) -> String? {
        guard let timestamp else { return nil }
        let resetDate = Date(timeIntervalSince1970: timestamp)
        let interval = resetDate.timeIntervalSince(now)
        guard interval > 0 else { return "即将重置" }

        if interval < 86_400 {
            let hours = Int(interval) / 3_600
            let minutes = (Int(interval) % 3_600) / 60
            if hours > 0 {
                return "\(hours)时\(minutes)分"
            }
            return "\(max(1, minutes))分"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEE"
        return formatter.string(from: resetDate)
    }
}
