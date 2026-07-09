import AppKit
import CodexUsageCore
import Foundation

@main
struct CodexUsageMain {
    static func main() async {
        let force = CommandLine.arguments.contains("--force")
        let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        let detector = ActivationDetector(
            frontmostBundleID: { bundleID },
            foregroundTTYCommand: { SystemProbe.foregroundTerminalCommand(bundleID: bundleID) }
        )

        guard force || detector.isCodexActive() else {
            FileHandle.standardOutput.write(Data(CodexLocalization().inactivePlaceholder.utf8))
            return
        }

        guard let codexPath = CodexExecutableLocator().resolve() else {
            FileHandle.standardOutput.write(Data(CodexLocalization().unavailableMessage.utf8))
            return
        }
        let client = AppServerClient(executableURL: codexPath)
        let output = await WidgetPolicy().output(client: client, cache: UsageCache())
        FileHandle.standardOutput.write(Data(output.utf8))
    }
}

private enum SystemProbe {
    static func foregroundTerminalCommand(bundleID: String?) -> String? {
        guard let bundleID else { return nil }
        let script: String
        switch bundleID {
        case "com.apple.Terminal":
            script = #"tell application "Terminal" to get tty of selected tab of front window"#
        case "com.googlecode.iterm2":
            script = #"tell application "iTerm2" to get tty of current session of current window"#
        default:
            return nil
        }

        guard let tty = run("/usr/bin/osascript", arguments: ["-e", script])?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !tty.isEmpty
        else {
            return nil
        }
        let ttyName = URL(fileURLWithPath: tty).lastPathComponent
        guard let processGroups = run(
            "/bin/ps",
            arguments: ["-t", ttyName, "-o", "tpgid="]
        ) else {
            return nil
        }
        let foregroundGroup = processGroups
            .split(whereSeparator: { $0.isWhitespace })
            .compactMap { Int($0) }
            .first { $0 > 0 }
        guard let foregroundGroup else { return nil }
        return run(
            "/bin/ps",
            arguments: ["-p", String(foregroundGroup), "-o", "comm="]
        )?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func run(_ executable: String, arguments: [String]) -> String? {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = output.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
