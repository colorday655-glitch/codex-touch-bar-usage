import Foundation

public struct CachedUsage: Codable, Equatable, Sendable {
    public let snapshot: RateLimitSnapshot
    public let updatedAt: Date

    public init(snapshot: RateLimitSnapshot, updatedAt: Date) {
        self.snapshot = snapshot
        self.updatedAt = updatedAt
    }

    public func isUsable(at now: Date, maxAge: TimeInterval = 300) -> Bool {
        let age = now.timeIntervalSince(updatedAt)
        return age >= 0 && age <= maxAge
    }
}

public struct UsageCache: Sendable {
    public let fileURL: URL

    public init(fileURL: URL = Self.defaultFileURL()) {
        self.fileURL = fileURL
    }

    public func load() throws -> CachedUsage? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(CachedUsage.self, from: data)
        } catch {
            return nil
        }
    }

    public func save(_ value: CachedUsage) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(value)
        try data.write(to: fileURL, options: .atomic)
    }

    public static func defaultFileURL(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        homeDirectory
            .appendingPathComponent("Library/Caches/CodexTouchBar", isDirectory: true)
            .appendingPathComponent("usage.json")
    }
}
