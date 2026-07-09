import Foundation

public protocol GitHubLatestReleaseChecking: Sendable {
    func latestTag() async throws -> String
}

public struct GitHubLatestReleaseClient: GitHubLatestReleaseChecking {
    private let repository: String
    private let session: URLSession

    public init(repository: String = "colorday655-glitch/codex-touch-bar-usage", session: URLSession = .shared) {
        self.repository = repository
        self.session = session
    }

    public func latestTag() async throws -> String {
        let url = URL(string: "https://api.github.com/repos/\(repository)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("CodexTouchBar", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw GateError.invalidResponse
        }
        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        return release.tagName
    }
}

public struct GitHubReleaseGate: Sendable {
    private let currentVersion: String
    private let checker: any GitHubLatestReleaseChecking
    private let cache: ReleaseGateCache
    private let now: @Sendable () -> Date
    private let cacheTTL: TimeInterval

    public init(
        currentVersion: String = CodexTouchBarVersion.current,
        checker: any GitHubLatestReleaseChecking = GitHubLatestReleaseClient(),
        cache: ReleaseGateCache = ReleaseGateCache(),
        now: @escaping @Sendable () -> Date = Date.init,
        cacheTTL: TimeInterval = 6 * 60 * 60
    ) {
        self.currentVersion = currentVersion
        self.checker = checker
        self.cache = cache
        self.now = now
        self.cacheTTL = cacheTTL
    }

    public func isCurrentVersionBlocked() async -> Bool {
        let currentDate = now()
        if let cached = cache.load(), cached.isFresh(at: currentDate, ttl: cacheTTL) {
            return cached.latestTag != currentVersion
        }

        do {
            let latest = try await checker.latestTag()
            let snapshot = ReleaseGateSnapshot(latestTag: latest, checkedAt: currentDate)
            try? cache.save(snapshot)
            return latest != currentVersion
        } catch {
            if let cached = cache.load() {
                return cached.latestTag != currentVersion
            }
            return false
        }
    }
}

public struct ReleaseGateCache: Sendable {
    private let url: URL

    public init(
        url: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches/CodexTouchBar/latest-release.json"),
    ) {
        self.url = url
    }

    public func load() -> ReleaseGateSnapshot? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ReleaseGateSnapshot.self, from: data)
    }

    public func save(_ snapshot: ReleaseGateSnapshot) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: url, options: [.atomic])
    }
}

public struct ReleaseGateSnapshot: Codable, Sendable {
    public let latestTag: String
    public let checkedAt: Date

    public init(latestTag: String, checkedAt: Date) {
        self.latestTag = latestTag
        self.checkedAt = checkedAt
    }

    func isFresh(at date: Date, ttl: TimeInterval) -> Bool {
        date.timeIntervalSince(checkedAt) < ttl
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String

    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
    }
}

private enum GateError: Error {
    case invalidResponse
}
