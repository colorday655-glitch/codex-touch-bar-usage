import Foundation
import Testing
@testable import CodexUsageCore

@Suite("GitHub release gate")
struct GitHubReleaseGateTests {
    @Test("blocks a release older than GitHub latest")
    func blocksOutdatedRelease() async {
        let gate = GitHubReleaseGate(
            currentVersion: "v1.0.5",
            checker: StubChecker(tag: "v1.0.6"),
            cache: ReleaseGateCache(url: tempURL("outdated.json")),
            now: { Date(timeIntervalSince1970: 0) },
            cacheTTL: 1
        )

        let blocked = await gate.isCurrentVersionBlocked()

        #expect(blocked)
    }

    @Test("allows the latest release")
    func allowsLatestRelease() async {
        let gate = GitHubReleaseGate(
            currentVersion: "v1.0.6",
            checker: StubChecker(tag: "v1.0.6"),
            cache: ReleaseGateCache(url: tempURL("latest.json")),
            now: { Date(timeIntervalSince1970: 0) },
            cacheTTL: 1
        )

        let blocked = await gate.isCurrentVersionBlocked()

        #expect(!blocked)
    }

    @Test("uses a fresh cached release snapshot when GitHub is unavailable")
    func usesFreshCache() async {
        let cacheURL = tempURL("cached.json")
        let cache = ReleaseGateCache(url: cacheURL)
        try? cache.save(ReleaseGateSnapshot(latestTag: "v1.0.6", checkedAt: Date()))

        let gate = GitHubReleaseGate(
            currentVersion: "v1.0.6",
            checker: ThrowingChecker(),
            cache: cache,
            now: { Date(timeIntervalSince1970: 0) },
            cacheTTL: 3600
        )

        let blocked = await gate.isCurrentVersionBlocked()

        #expect(!blocked)
    }

    private func tempURL(_ name: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("CodexTouchBarTests-\(UUID().uuidString)")
            .appendingPathComponent(name)
    }
}

private struct StubChecker: GitHubLatestReleaseChecking {
    let tag: String

    func latestTag() async throws -> String {
        tag
    }
}

private struct ThrowingChecker: GitHubLatestReleaseChecking {
    func latestTag() async throws -> String {
        throw URLError(.notConnectedToInternet)
    }
}
