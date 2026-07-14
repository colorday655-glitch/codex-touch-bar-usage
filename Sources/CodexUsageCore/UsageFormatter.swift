import Foundation

public struct UsageFormatter: Sendable {
    private let now: Date
    private let timeZone: TimeZone
    private let localization: CodexLocalization

    public init(
        now: Date = Date(),
        timeZone: TimeZone = .current,
        locale: Locale = .autoupdatingCurrent
    ) {
        self.now = now
        self.timeZone = timeZone
        self.localization = CodexLocalization(locale: locale)
    }

    public func render(_ snapshot: RateLimitSnapshot, stale: Bool = false) -> String {
        let selected = snapshot.selectedWindows()
        var rows = [
            resetCreditRow(snapshot.resetCredits),
            row(label: localization.weeklyLabel, window: selected.weekly, resetStyle: .weekly),
        ]
        if stale {
            rows[rows.count - 1] += " ·"
        }
        return rows.joined(separator: "        ")
    }

    private func resetCreditRow(_ resetCredits: RateLimitResetCredits?) -> String {
        guard let availableCount = resetCredits?.availableCount else {
            return "\(paddedLabel(localization.resetCreditsLabel)) \(emptyBar) --"
        }

        let filledCount = min(10, max(0, availableCount))
        let bar = String(repeating: "🟩", count: filledCount)
            + String(repeating: "⬜", count: 10 - filledCount)
        return "\(paddedLabel(localization.resetCreditsLabel)) \(bar) \(availableCount)  --"
    }

    private func row(label: String, window: RateLimitWindow?, resetStyle: CodexLocalization.ResetStyle) -> String {
        guard let window, let usedPercent = window.usedPercent, usedPercent.isFinite else {
            return "\(paddedLabel(label)) \(emptyBar) --"
        }

        let remaining = min(100, max(0, 100 - usedPercent))
        let filledCount = min(10, max(0, Int((remaining / 10).rounded())))
        let bar = String(repeating: "🟩", count: filledCount)
            + String(repeating: "⬜", count: 10 - filledCount)
        let percentage = Int(remaining.rounded())
        let reset = resetDescription(window.resetsAt, style: resetStyle) ?? "--"
        return "\(paddedLabel(label)) \(bar) \(percentage)%  \(reset)"
    }

    private var emptyBar: String {
        String(repeating: "⬜", count: 10)
    }

    private func paddedLabel(_ label: String) -> String {
        let targetWidth = localization.firstColumnTargetWidth
        let currentWidth = label.displayWidth
        guard currentWidth < targetWidth else { return label }
        return label + String(repeating: " ", count: targetWidth - currentWidth)
    }

    private func resetDescription(_ timestamp: TimeInterval?, style: CodexLocalization.ResetStyle) -> String? {
        guard let timestamp else { return nil }
        let resetDate = Date(timeIntervalSince1970: timestamp)
        let interval = resetDate.timeIntervalSince(now)
        guard interval > 0 else { return localization.resetSoon }

        return localization.resetFormatter(style: style, timeZone: timeZone).string(from: resetDate)
    }
}

private extension String {
    var displayWidth: Int {
        unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult + scalar.displayWidth
        }
    }
}

private extension UnicodeScalar {
    var displayWidth: Int {
        switch value {
        case 0x0000...0x001F, 0x007F...0x009F:
            return 0
        case 0x1100...0x115F,
            0x2329, 0x232A,
            0x2E80...0x3247,
            0x3250...0x4DBF,
            0x4E00...0xA4C6,
            0xA960...0xA97C,
            0xAC00...0xD7A3,
            0xF900...0xFAFF,
            0xFE10...0xFE19,
            0xFE30...0xFE6B,
            0xFF01...0xFF60,
            0xFFE0...0xFFE6:
            return 2
        default:
            return 1
        }
    }
}
