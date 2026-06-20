import Foundation
import Testing
@testable import CodexUsageCore

@Suite("Widget output policy")
struct WidgetPolicyTests {
    private let now = Date(timeIntervalSince1970: 1_000)
    private let snapshot = RateLimitSnapshot(
        primary: RateLimitWindow(usedPercent: 28, windowDurationMins: 300, resetsAt: 2_000),
        secondary: RateLimitWindow(usedPercent: 56, windowDurationMins: 10_080, resetsAt: 3_000)
    )

    @Test("formats and caches a successful refresh")
    func formatsAndCachesSuccess() async throws {
        let cache = temporaryCache()
        let output = await WidgetPolicy().output(
            client: StubFetcher(result: .success(snapshot)),
            cache: cache,
            now: now
        )

        #expect(output.contains("72%"))
        #expect(output.contains("44%"))
        #expect(try cache.load()?.snapshot == snapshot)
    }

    @Test("uses a fresh cache with a stale marker after failure")
    func usesFreshCacheAfterFailure() async throws {
        let cache = temporaryCache()
        try cache.save(CachedUsage(snapshot: snapshot, updatedAt: now.addingTimeInterval(-299)))

        let output = await WidgetPolicy().output(
            client: StubFetcher(result: .failure(.disconnected)),
            cache: cache,
            now: now
        )

        #expect(output.hasSuffix(" ·"))
        #expect(output.contains("72%"))
    }

    @Test("does not use an expired cache")
    func rejectsExpiredCache() async throws {
        let cache = temporaryCache()
        try cache.save(CachedUsage(snapshot: snapshot, updatedAt: now.addingTimeInterval(-301)))

        let output = await WidgetPolicy().output(
            client: StubFetcher(result: .failure(.disconnected)),
            cache: cache,
            now: now
        )

        #expect(output == "Codex 用量暂不可用")
    }

    @Test("shows a signed-out message")
    func mapsUnauthenticatedMessage() async {
        let output = await WidgetPolicy().output(
            client: StubFetcher(result: .failure(.unauthenticated)),
            cache: temporaryCache(),
            now: now
        )

        #expect(output == "请先在 Codex 登录")
    }

    private func temporaryCache() -> UsageCache {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        return UsageCache(fileURL: directory.appendingPathComponent("usage.json"))
    }
}

private struct StubFetcher: RateLimitFetching {
    let result: Result<RateLimitSnapshot, AppServerError>

    func fetchRateLimits() async throws -> RateLimitSnapshot {
        try result.get()
    }
}
