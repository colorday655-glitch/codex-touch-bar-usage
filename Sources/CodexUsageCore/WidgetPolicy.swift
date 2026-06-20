import Foundation

public struct WidgetPolicy: Sendable {
    public init() {}

    public func output(
        client: any RateLimitFetching,
        cache: UsageCache,
        now: Date = Date()
    ) async -> String {
        do {
            let snapshot = try await client.fetchRateLimits()
            try? cache.save(CachedUsage(snapshot: snapshot, updatedAt: now))
            return UsageFormatter(now: now).render(snapshot)
        } catch AppServerError.unauthenticated {
            return "请先在 Codex 登录"
        } catch {
            guard
                let cached = try? cache.load(),
                cached.isUsable(at: now)
            else {
                return "Codex 用量暂不可用"
            }
            return UsageFormatter(now: now).render(cached.snapshot, stale: true)
        }
    }
}
