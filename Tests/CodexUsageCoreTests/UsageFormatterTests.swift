import Foundation
import Testing
@testable import CodexUsageCore

@Suite("Touch Bar usage formatting")
struct UsageFormatterTests {
    private let now = Date(timeIntervalSince1970: 1_749_991_720)

    @Test("renders five-hour and weekly rows")
    func rendersFiveHourAndWeeklyRows() {
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
            )
        )

        let output = UsageFormatter(now: now).render(snapshot)

        #expect(output.split(separator: "\n").count == 2)
        #expect(output.contains("5小时"))
        #expect(output.contains("72%"))
        #expect(output.contains("本周"))
        #expect(output.contains("44%"))
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
            secondary: RateLimitWindow(usedPercent: 125, windowDurationMins: 10_080, resetsAt: nil)
        )

        let output = UsageFormatter(now: now).render(snapshot)

        #expect(output.contains("100%"))
        #expect(output.contains("0%"))
    }

    @Test("marks stale output and tolerates a missing window")
    func marksStaleAndMissingWindow() {
        let snapshot = RateLimitSnapshot(
            primary: RateLimitWindow(usedPercent: 28, windowDurationMins: 300, resetsAt: nil),
            secondary: nil
        )

        let output = UsageFormatter(now: now).render(snapshot, stale: true)

        #expect(output.contains("72%"))
        #expect(output.contains("本周  ▱▱▱▱▱ --"))
        #expect(output.hasSuffix(" ·"))
    }

    @Test("labels past resets as imminent")
    func labelsPastResetAsImminent() {
        let snapshot = RateLimitSnapshot(
            primary: RateLimitWindow(usedPercent: 28, windowDurationMins: 300, resetsAt: now.timeIntervalSince1970 - 1),
            secondary: nil
        )

        let output = UsageFormatter(now: now).render(snapshot)

        #expect(output.contains("即将重置"))
    }
}
