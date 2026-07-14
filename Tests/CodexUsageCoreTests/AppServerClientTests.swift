import Foundation
import Testing
@testable import CodexUsageCore

@Suite("Codex app-server client", .serialized)
struct AppServerClientTests {
    private var fakeServerURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/fake-app-server.sh")
    }

    @Test("prefers the codex multi-bucket snapshot")
    func readsCodexBucket() async throws {
        let client = AppServerClient(
            executableURL: fakeServerURL,
            environment: ["FAKE_MODE": "multi"],
            timeout: 2
        )

        let snapshot = try await client.fetchRateLimits()

        #expect(snapshot.primary?.usedPercent == 28)
        #expect(snapshot.secondary?.usedPercent == 56)
        #expect(snapshot.resetCredits?.availableCount == 2)
    }

    @Test("falls back to the compatible snapshot")
    func readsFallbackSnapshot() async throws {
        let client = AppServerClient(
            executableURL: fakeServerURL,
            environment: ["FAKE_MODE": "fallback"],
            timeout: 2
        )

        let snapshot = try await client.fetchRateLimits()

        #expect(snapshot.primary?.usedPercent == 31)
        #expect(snapshot.secondary?.usedPercent == 57)
        #expect(snapshot.resetCredits?.availableCount == 2)
    }

    @Test("maps signed-out errors")
    func mapsUnauthenticatedError() async {
        let client = AppServerClient(
            executableURL: fakeServerURL,
            environment: ["FAKE_MODE": "unauthenticated"],
            timeout: 2
        )

        await #expect(throws: AppServerError.unauthenticated) {
            try await client.fetchRateLimits()
        }
    }

    @Test("terminates a timed-out server")
    func timesOut() async {
        let client = AppServerClient(
            executableURL: fakeServerURL,
            environment: ["FAKE_MODE": "timeout"],
            timeout: 0.05
        )

        await #expect(throws: AppServerError.timeout) {
            try await client.fetchRateLimits()
        }
    }
}
