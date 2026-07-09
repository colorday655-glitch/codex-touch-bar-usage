import Foundation

public struct CodexExecutableLocator: Sendable {
    private let environment: [String: String]

    public init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        self.environment = environment
    }

    public func resolve() -> URL? {
        if let explicit = environment["CODEX_EXECUTABLE"], isExecutable(explicit) {
            return URL(fileURLWithPath: explicit)
        }

        if let fromPath = resolveFromPath() {
            return fromPath
        }

        for candidate in Self.candidatePaths {
            if isExecutable(candidate) {
                return URL(fileURLWithPath: candidate)
            }
        }

        return nil
    }

    private func resolveFromPath() -> URL? {
        guard let path = environment["PATH"], !path.isEmpty else {
            return nil
        }

        for directory in path.split(separator: ":") {
            let candidate = URL(fileURLWithPath: String(directory))
                .appendingPathComponent("codex")
                .path
            if isExecutable(candidate) {
                return URL(fileURLWithPath: candidate)
            }
        }
        return nil
    }

    private func isExecutable(_ path: String) -> Bool {
        FileManager.default.isExecutableFile(atPath: path)
    }

    private static let candidatePaths = [
        "/Applications/ChatGPT.app/Contents/Resources/codex",
        "/Applications/Codex.app/Contents/Resources/codex",
        "\(NSHomeDirectory())/Applications/ChatGPT.app/Contents/Resources/codex",
        "\(NSHomeDirectory())/Applications/Codex.app/Contents/Resources/codex",
    ]
}
