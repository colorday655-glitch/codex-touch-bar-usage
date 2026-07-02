import Testing
@testable import CodexUsageCore

@Suite("Codex localization")
struct LocalizationTests {
    @Test("uses a non-empty placeholder when inactive")
    func inactivePlaceholderIsNonEmpty() {
        #expect(CodexLocalization().inactivePlaceholder.count == 1)
    }
}
