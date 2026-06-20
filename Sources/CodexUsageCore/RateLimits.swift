import Foundation

public struct RateLimitWindow: Codable, Equatable, Sendable {
    public let usedPercent: Double?
    public let windowDurationMins: Int?
    public let resetsAt: TimeInterval?

    public init(
        usedPercent: Double?,
        windowDurationMins: Int?,
        resetsAt: TimeInterval?
    ) {
        self.usedPercent = usedPercent
        self.windowDurationMins = windowDurationMins
        self.resetsAt = resetsAt
    }
}

public struct RateLimitSnapshot: Codable, Equatable, Sendable {
    public let primary: RateLimitWindow?
    public let secondary: RateLimitWindow?

    public init(primary: RateLimitWindow?, secondary: RateLimitWindow?) {
        self.primary = primary
        self.secondary = secondary
    }

    public func selectedWindows() -> (
        fiveHour: RateLimitWindow?,
        weekly: RateLimitWindow?
    ) {
        let windows = [primary, secondary].compactMap { $0 }
        let fiveHour = windows.first { window in
            guard let duration = window.windowDurationMins else { return false }
            return abs(duration - 300) <= 60
        }
        let weekly = windows.first { window in
            guard let duration = window.windowDurationMins else { return false }
            return abs(duration - 10_080) <= 1_440
        }

        return (fiveHour ?? primary, weekly ?? secondary)
    }
}
