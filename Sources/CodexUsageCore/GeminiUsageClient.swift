import Foundation

public protocol GeminiCredentialProviding: Sendable {
    func readAccessToken() throws -> String
}

public enum GeminiUsageError: Error, Equatable, Sendable {
    case noCredentials
    case invalidCredentials
    case invalidResponse
    case httpStatus(Int)
    case transport(String)
}

public struct GeminiUsageClient: RateLimitFetching, Sendable {
    public typealias Transport = @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

    private let endpoint: URL
    private let credentialStore: any GeminiCredentialProviding
    private let transport: Transport

    public init(
        endpoint: URL = URL(string: "https://daily-cloudcode-pa.googleapis.com/v1internal")!,
        credentialStore: any GeminiCredentialProviding = KeychainGeminiCredentialStore(),
        transport: @escaping Transport = GeminiUsageClient.liveTransport
    ) {
        self.endpoint = endpoint
        self.credentialStore = credentialStore
        self.transport = transport
    }

    public func fetchRateLimits() async throws -> RateLimitSnapshot {
        let token = try credentialStore.readAccessToken()
        let project = try await post(
            method: "loadCodeAssist",
            token: token,
            payload: [
                "metadata": [
                    "ideType": "ANTIGRAVITY",
                    "platform": "PLATFORM_UNSPECIFIED",
                    "pluginType": "GEMINI",
                ],
            ]
        )
        guard let project = project["cloudaicompanionProject"] as? String, !project.isEmpty else {
            throw GeminiUsageError.invalidResponse
        }

        let summary = try await post(
            method: "retrieveUserQuotaSummary",
            token: token,
            payload: ["project": project]
        )
        return try decodeSnapshot(from: summary)
    }

    private func post(
        method: String,
        token: String,
        payload: [String: Any]
    ) async throws -> [String: Any] {
        let url = endpoint.appendingPathComponent(":" + method)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("antigravity/2.35.0 \(Self.platform)", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await transport(request)
        } catch let error as GeminiUsageError {
            throw error
        } catch {
            throw GeminiUsageError.transport(error.localizedDescription)
        }
        guard response.statusCode == 200 else {
            throw GeminiUsageError.httpStatus(response.statusCode)
        }
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GeminiUsageError.invalidResponse
        }
        return object
    }

    private func decodeSnapshot(from object: [String: Any]) throws -> RateLimitSnapshot {
        guard let groups = object["groups"] as? [[String: Any]] else {
            throw GeminiUsageError.invalidResponse
        }
        let group = groups.first { group in
            (group["displayName"] as? String)?.lowercased().contains("gemini") == true
        }
        guard let buckets = group?["buckets"] as? [[String: Any]] else {
            throw GeminiUsageError.invalidResponse
        }

        var primary: RateLimitWindow?
        var weekly: RateLimitWindow?
        for bucket in buckets {
            guard
                let window = bucket["window"] as? String,
                let remaining = bucket["remainingFraction"] as? NSNumber
            else { continue }
            let reset = (bucket["resetTime"] as? String).flatMap(Self.timestamp)
            let value = min(100, max(0, 100 - remaining.doubleValue * 100))
            let rateLimit = RateLimitWindow(
                usedPercent: value,
                windowDurationMins: window == "5h" ? 300 : (window == "weekly" ? 10_080 : nil),
                resetsAt: reset
            )
            if window == "5h" { primary = rateLimit }
            if window == "weekly" { weekly = rateLimit }
        }
        guard primary != nil || weekly != nil else {
            throw GeminiUsageError.invalidResponse
        }
        return RateLimitSnapshot(primary: primary, secondary: weekly)
    }

    private static func timestamp(_ value: String) -> TimeInterval? {
        ISO8601DateFormatter().date(from: value)?.timeIntervalSince1970
    }

    private static let platform = "darwin/\(Self.architecture)"

    private static var architecture: String {
#if arch(arm64)
        "arm64"
#else
        "amd64"
#endif
    }

    public static func liveTransport(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw GeminiUsageError.invalidResponse
        }
        return (data, response)
    }
}

public struct KeychainGeminiCredentialStore: GeminiCredentialProviding, Sendable {
    public init() {}

    public func readAccessToken() throws -> String {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", "gemini", "-a", "antigravity", "-w"]
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw GeminiUsageError.noCredentials
        }
        guard process.terminationStatus == 0 else { throw GeminiUsageError.noCredentials }
        let raw = output.fileHandleForReading.readDataToEndOfFile()
        return try Self.parse(raw)
    }

    static func parse(_ data: Data) throws -> String {
        let raw = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonData: Data
        if let encoded = raw.stripPrefix("go-keyring-base64:") {
            guard let decoded = Data(base64Encoded: encoded) else { throw GeminiUsageError.invalidCredentials }
            jsonData = decoded
        } else {
            jsonData = Data(raw.utf8)
        }
        guard
            let root = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
            let token = root["token"] as? [String: Any],
            let accessToken = token["access_token"] as? String,
            !accessToken.isEmpty
        else { throw GeminiUsageError.invalidCredentials }
        return accessToken
    }
}

private extension String {
    func stripPrefix(_ prefix: String) -> String? {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : nil
    }
}
