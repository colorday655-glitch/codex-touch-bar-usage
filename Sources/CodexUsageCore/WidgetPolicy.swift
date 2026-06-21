import Foundation

public struct WidgetPolicy: Sendable {
    public init() {}

    public func output(
        client: any RateLimitFetching,
        cache: UsageCache,
        now: Date = Date(),
        locale: Locale = .autoupdatingCurrent
    ) async -> String {
        let localization = CodexLocalization(locale: locale)
        do {
            let snapshot = try await client.fetchRateLimits()
            try? cache.save(CachedUsage(snapshot: snapshot, updatedAt: now))
            return UsageFormatter(now: now, locale: locale).render(snapshot)
        } catch AppServerError.unauthenticated {
            return localization.unauthenticatedMessage
        } catch {
            guard
                let cached = try? cache.load(),
                cached.isUsable(at: now)
            else {
                return localization.unavailableMessage
            }
            return UsageFormatter(now: now, locale: locale).render(cached.snapshot, stale: true)
        }
    }
}
