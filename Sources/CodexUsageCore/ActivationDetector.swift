import Foundation

public struct ActivationDetector: Sendable {
    private let frontmostBundleID: @Sendable () -> String?
    private let foregroundTTYCommand: @Sendable () -> String?

    public init(
        frontmostBundleID: @escaping @Sendable () -> String?,
        foregroundTTYCommand: @escaping @Sendable () -> String?
    ) {
        self.frontmostBundleID = frontmostBundleID
        self.foregroundTTYCommand = foregroundTTYCommand
    }

    public func isCodexActive() -> Bool {
        guard let bundleID = frontmostBundleID() else { return false }
        if bundleID == "com.openai.codex" {
            return true
        }
        let terminalBundleIDs = ["com.apple.Terminal", "com.googlecode.iterm2"]
        guard terminalBundleIDs.contains(bundleID), let command = foregroundTTYCommand() else {
            return false
        }
        let executable = URL(fileURLWithPath: command.trimmingCharacters(in: .whitespacesAndNewlines))
            .lastPathComponent
        return executable == "codex"
    }
}

