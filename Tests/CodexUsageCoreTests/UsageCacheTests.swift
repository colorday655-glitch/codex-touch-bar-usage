import Foundation
import Testing
@testable import CodexUsageCore

@Suite("Credential-free usage cache")
struct UsageCacheTests {
    private let snapshot = RateLimitSnapshot(
        primary: RateLimitWindow(usedPercent: 28, windowDurationMins: 300, resetsAt: 2_000),
        secondary: RateLimitWindow(usedPercent: 56, windowDurationMins: 10_080, resetsAt: 3_000)
    )

    @Test("expires after five minutes")
    func expiresAfterFiveMinutes() {
        let stored = CachedUsage(
            snapshot: snapshot,
            updatedAt: Date(timeIntervalSince1970: 1_000)
        )

        #expect(stored.isUsable(at: Date(timeIntervalSince1970: 1_299)))
        #expect(!stored.isUsable(at: Date(timeIntervalSince1970: 1_301)))
        #expect(!stored.isUsable(at: Date(timeIntervalSince1970: 999)))
    }

    @Test("round trips only non-sensitive usage fields")
    func roundTripsWithoutSensitiveFields() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("usage.json")
        let cache = UsageCache(fileURL: fileURL)
        let stored = CachedUsage(
            snapshot: snapshot,
            updatedAt: Date(timeIntervalSince1970: 1_000)
        )

        try cache.save(stored)

        #expect(try cache.load() == stored)
        let text = try String(contentsOf: fileURL, encoding: .utf8).lowercased()
        #expect(!text.contains("token"))
        #expect(!text.contains("auth"))
        #expect(!text.contains("account"))
    }

    @Test("treats malformed cache as absent")
    func malformedCacheIsAbsent() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("usage.json")
        try Data("not-json".utf8).write(to: fileURL)

        #expect(try UsageCache(fileURL: fileURL).load() == nil)
    }
}
