import Foundation
import Testing
@testable import CodexUsageCore

@Suite("Touch Bar usage formatting")
struct UsageFormatterTests {
    private let now = Date(timeIntervalSince1970: 1_749_991_720)
    private let timeZone = TimeZone(identifier: "Asia/Shanghai")!
    private let chineseLocale = Locale(identifier: "zh_CN")
    private let englishLocale = Locale(identifier: "en_US")

    @Test("renders aligned rows with ten-segment bars")
    func rendersAlignedRowsWithTenSegmentBars() {
        let snapshot = RateLimitSnapshot(
            primary: RateLimitWindow(
                usedPercent: 28,
                windowDurationMins: 300,
                resetsAt: 1_750_000_000
            ),
            secondary: RateLimitWindow(
                usedPercent: 56,
                windowDurationMins: 10_080,
                resetsAt: 1_750_500_000
            ),
            resetCredits: RateLimitResetCredits(
                availableCount: 2,
                credits: [
                    RateLimitResetCredit(
                        id: "RateLimitResetCredit_1",
                        resetType: "codexRateLimits",
                        status: "available",
                        grantedAt: 1_781_654_400,
                        expiresAt: 1_784_246_400,
                        title: "Full reset (Weekly + 5 hr)",
                        description: "Ready to redeem"
                    )
                ]
            )
        )

        let output = UsageFormatter(now: now, timeZone: timeZone, locale: chineseLocale).render(snapshot)

        #expect(!output.contains("\n"))
        #expect(
            output == """
            可重置次数 2次 可用 · 到期 7月17日 08:00        1周        🟩🟩🟩🟩⬜⬜⬜⬜⬜⬜ 44%  6月21日
            """
        )
    }

    @Test("renders localized English labels and dates")
    func rendersLocalizedEnglishLabelsAndDates() {
        let snapshot = RateLimitSnapshot(
            primary: RateLimitWindow(
                usedPercent: 28,
                windowDurationMins: 300,
                resetsAt: 1_750_000_000
            ),
            secondary: RateLimitWindow(
                usedPercent: 56,
                windowDurationMins: 10_080,
                resetsAt: 1_750_500_000
            ),
            resetCredits: RateLimitResetCredits(availableCount: 2, credits: nil)
        )

        let output = UsageFormatter(now: now, timeZone: timeZone, locale: englishLocale).render(snapshot)

        #expect(output.contains("Reset credits"))
        #expect(output.contains("2x"))
        #expect(output.contains("1w"))
        #expect(output.contains("Jun"))
    }

    @Test("selects windows by duration when roles are reordered")
    func selectsReorderedWindowsByDuration() {
        let snapshot = RateLimitSnapshot(
            primary: RateLimitWindow(usedPercent: 60, windowDurationMins: 10_080, resetsAt: nil),
            secondary: RateLimitWindow(usedPercent: 10, windowDurationMins: 300, resetsAt: nil)
        )

        let selected = snapshot.selectedWindows()

        #expect(selected.fiveHour?.usedPercent == 10)
        #expect(selected.weekly?.usedPercent == 60)
    }

    @Test("clamps remaining percentages")
    func clampsRemainingPercentages() {
        let snapshot = RateLimitSnapshot(
            primary: RateLimitWindow(usedPercent: -5, windowDurationMins: 300, resetsAt: nil),
            secondary: RateLimitWindow(usedPercent: 125, windowDurationMins: 10_080, resetsAt: nil),
            resetCredits: RateLimitResetCredits(availableCount: 2, credits: nil)
        )

        let output = UsageFormatter(now: now, timeZone: timeZone, locale: chineseLocale).render(snapshot)

        #expect(output.contains("2次"))
        #expect(output.contains("可重置次数"))
    }

    @Test("marks stale output and tolerates a missing window")
    func marksStaleAndMissingWindow() {
        let snapshot = RateLimitSnapshot(
            primary: RateLimitWindow(usedPercent: 28, windowDurationMins: 300, resetsAt: nil),
            secondary: RateLimitWindow(
                usedPercent: 28,
                windowDurationMins: 10_080,
                resetsAt: now.timeIntervalSince1970 - 1
            ),
            resetCredits: RateLimitResetCredits(availableCount: 2, credits: nil)
        )

        let output = UsageFormatter(now: now, timeZone: timeZone, locale: chineseLocale).render(snapshot, stale: true)

        #expect(output.contains("即将重置"))
        #expect(output.contains("可重置次数"))
        #expect(output.hasSuffix(" ·"))
    }

    @Test("labels past resets as imminent")
    func labelsPastResetAsImminent() {
        let snapshot = RateLimitSnapshot(
            primary: nil,
            secondary: RateLimitWindow(usedPercent: 28, windowDurationMins: 10_080, resetsAt: now.timeIntervalSince1970 - 1),
            resetCredits: RateLimitResetCredits(availableCount: 2, credits: nil)
        )

        let output = UsageFormatter(now: now, timeZone: timeZone, locale: chineseLocale).render(snapshot)

        #expect(output.contains("即将重置"))
    }
}
