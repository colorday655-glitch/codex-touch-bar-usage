import Testing
@testable import CodexUsageCore

@Suite("Codex activation detection")
struct ActivationDetectorTests {
    @Test("activates for Codex desktop")
    func codexDesktopIsActive() {
        let detector = ActivationDetector(
            frontmostBundleID: { "com.openai.codex" },
            foregroundTTYCommand: { nil }
        )
        #expect(detector.isCodexActive())
    }

    @Test("activates for Codex as the terminal foreground command")
    func terminalCodexIsActive() {
        let detector = ActivationDetector(
            frontmostBundleID: { "com.apple.Terminal" },
            foregroundTTYCommand: { "/Applications/Codex.app/Contents/Resources/codex" }
        )
        #expect(detector.isCodexActive())
    }

    @Test("rejects unrelated terminal commands")
    func unrelatedTerminalCommandIsInactive() {
        let detector = ActivationDetector(
            frontmostBundleID: { "com.apple.Terminal" },
            foregroundTTYCommand: { "zsh" }
        )
        #expect(!detector.isCodexActive())
    }

    @Test("rejects a background Codex process in another app")
    func unrelatedAppIsInactive() {
        let detector = ActivationDetector(
            frontmostBundleID: { "com.apple.Safari" },
            foregroundTTYCommand: { "codex" }
        )
        #expect(!detector.isCodexActive())
    }
}

