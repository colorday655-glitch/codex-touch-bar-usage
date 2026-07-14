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

public struct RateLimitResetCredits: Codable, Equatable, Sendable {
    public let availableCount: Int
    public let credits: [RateLimitResetCredit]?

    public init(availableCount: Int, credits: [RateLimitResetCredit]?) {
        self.availableCount = availableCount
        self.credits = credits
    }
}

public struct RateLimitResetCredit: Codable, Equatable, Sendable {
    public let id: String
    public let resetType: String
    public let status: String
    public let grantedAt: TimeInterval
    public let expiresAt: TimeInterval?
    public let title: String?
    public let description: String?

    public init(
        id: String,
        resetType: String,
        status: String,
        grantedAt: TimeInterval,
        expiresAt: TimeInterval?,
        title: String?,
        description: String?
    ) {
        self.id = id
        self.resetType = resetType
        self.status = status
        self.grantedAt = grantedAt
        self.expiresAt = expiresAt
        self.title = title
        self.description = description
    }
}

public struct RateLimitSnapshot: Codable, Equatable, Sendable {
    public let primary: RateLimitWindow?
    public let secondary: RateLimitWindow?
    public let resetCredits: RateLimitResetCredits?

    public init(
        primary: RateLimitWindow?,
        secondary: RateLimitWindow?,
        resetCredits: RateLimitResetCredits? = nil
    ) {
        self.primary = primary
        self.secondary = secondary
        self.resetCredits = resetCredits
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
