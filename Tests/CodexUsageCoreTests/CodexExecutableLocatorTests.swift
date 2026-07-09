import Foundation
import Testing
@testable import CodexUsageCore

@Suite("Codex executable locator")
struct CodexExecutableLocatorTests {
    @Test("prefers the explicit environment override")
    func prefersExplicitOverride() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let executable = tempDir.appendingPathComponent("codex")
        try "#!/bin/sh\nexit 0\n".data(using: .utf8)!.write(to: executable)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)

        let locator = CodexExecutableLocator(environment: [
            "CODEX_EXECUTABLE": executable.path,
            "PATH": "",
        ])

        #expect(locator.resolve() == executable)
    }

    @Test("falls back to PATH lookup")
    func fallsBackToPathLookup() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let executable = tempDir.appendingPathComponent("codex")
        try "#!/bin/sh\nexit 0\n".data(using: .utf8)!.write(to: executable)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)

        let locator = CodexExecutableLocator(environment: [
            "PATH": tempDir.path,
        ])

        #expect(locator.resolve() == executable)
    }
}
