import Foundation
import Testing
@testable import CodexUsageCore

@Suite("Gemini quota client")
struct GeminiUsageClientTests {
    @Test("maps Gemini five-hour and weekly buckets")
    func mapsGeminiBuckets() async throws {
        let calls = CallRecorder()
        let client = GeminiUsageClient(
            credentialStore: StubGeminiCredentialStore(token: "test-token"),
            transport: { request in
                await calls.record(request)
                if request.url?.absoluteString.contains("loadCodeAssist") == true {
                    return Self.response("{\"cloudaicompanionProject\":\"projects/test-project\"}")
                }
                return Self.response(Self.summaryJSON)
            }
        )

        let snapshot = try await client.fetchRateLimits()

        #expect(snapshot.primary?.usedPercent == 62.5)
        #expect(snapshot.primary?.windowDurationMins == 300)
        #expect(snapshot.secondary?.usedPercent == 10)
        #expect(snapshot.secondary?.windowDurationMins == 10_080)
        #expect(await calls.values.count == 2)
        #expect(await calls.values.allSatisfy { $0.value(forHTTPHeaderField: "Authorization") == "Bearer test-token" })
    }

    @Test("fails when quota endpoint returns an HTTP error")
    func failsOnHTTPError() async {
        let client = GeminiUsageClient(
            credentialStore: StubGeminiCredentialStore(token: "test-token"),
            transport: { request in
                let status = request.url?.absoluteString.contains("loadCodeAssist") == true ? 200 : 429
                return Self.response("{}", status: status)
            }
        )

        await #expect(throws: GeminiUsageError.self) {
            _ = try await client.fetchRateLimits()
        }
    }

    private static func response(_ body: String, status: Int = 200) -> (Data, HTTPURLResponse) {
        (
            Data(body.utf8),
            HTTPURLResponse(
                url: URL(string: "https://daily-cloudcode-pa.googleapis.com")!,
                statusCode: status,
                httpVersion: nil,
                headerFields: nil
            )!
        )
    }

    private static let summaryJSON = """
    {
      "groups": [
        {"displayName":"Claude and GPT models","buckets":[{"bucketId":"other-5h","window":"5h","resetTime":"2026-12-01T00:00:00Z","remainingFraction":0.99}]},
        {"displayName":"Gemini Models","buckets":[
          {"bucketId":"gemini-weekly","window":"weekly","resetTime":"2026-12-07T00:00:00Z","remainingFraction":0.9},
          {"bucketId":"gemini-5h","window":"5h","resetTime":"2026-12-01T00:00:00Z","remainingFraction":0.375}
        ]}
      ]
    }
    """
}

private struct StubGeminiCredentialStore: GeminiCredentialProviding {
    let token: String

    func readAccessToken() throws -> String { token }
}

private actor CallRecorder {
    var values: [URLRequest] = []

    func record(_ request: URLRequest) {
        values.append(request)
    }
}
