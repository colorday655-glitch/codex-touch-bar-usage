import Foundation

public enum AppServerError: Error, Equatable, Sendable {
    case launchFailed(String)
    case timeout
    case disconnected
    case rpc(code: Int, message: String)
    case invalidResponse
    case unauthenticated
}

public protocol RateLimitFetching: Sendable {
    func fetchRateLimits() async throws -> RateLimitSnapshot
}

public struct AppServerClient: RateLimitFetching, Sendable {
    private let executableURL: URL
    private let environment: [String: String]
    private let timeout: TimeInterval

    public init(
        executableURL: URL,
        environment: [String: String] = [:],
        timeout: TimeInterval = 8
    ) {
        self.executableURL = executableURL
        self.environment = environment
        self.timeout = timeout
    }

    public func fetchRateLimits() async throws -> RateLimitSnapshot {
        try await Task.detached {
            try fetchBlocking()
        }.value
    }

    private func fetchBlocking() throws -> RateLimitSnapshot {
        let process = Process()
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.executableURL = executableURL
        process.arguments = ["app-server", "--stdio"]
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, override in
            override
        }

        do {
            try process.run()
        } catch {
            throw AppServerError.launchFailed(error.localizedDescription)
        }
        defer {
            try? inputPipe.fileHandleForWriting.close()
            if process.isRunning {
                process.terminate()
            }
        }

        let lines = LineQueue()
        DispatchQueue.global(qos: .userInitiated).async {
            while true {
                let data = outputPipe.fileHandleForReading.availableData
                guard !data.isEmpty else {
                    lines.finish()
                    return
                }
                lines.append(data)
            }
        }

        let deadline = Date().addingTimeInterval(timeout)
        write(
            #"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"clientInfo":{"name":"codex-touch-bar","title":"Codex Touch Bar","version":"0.1.0"},"capabilities":{}}}"#,
            to: inputPipe.fileHandleForWriting
        )
        _ = try response(id: 1, from: lines, deadline: deadline)
        write(
            #"{"jsonrpc":"2.0","id":2,"method":"account/rateLimits/read","params":{}}"#,
            to: inputPipe.fileHandleForWriting
        )
        let rateLimitResponse = try response(id: 2, from: lines, deadline: deadline)
        return try decodeRateLimits(from: rateLimitResponse)
    }

    private func write(_ message: String, to handle: FileHandle) {
        handle.write(Data((message + "\n").utf8))
    }

    private func response(id: Int, from lines: LineQueue, deadline: Date) throws -> [String: Any] {
        while Date() < deadline {
            guard let line = lines.next(until: deadline) else {
                throw AppServerError.timeout
            }
            guard
                let data = line.data(using: .utf8),
                let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                continue
            }
            if (object["id"] as? NSNumber)?.intValue == id {
                return object
            }
        }
        throw AppServerError.timeout
    }

    private func decodeRateLimits(from object: [String: Any]) throws -> RateLimitSnapshot {
        if let error = object["error"] as? [String: Any] {
            let code = (error["code"] as? NSNumber)?.intValue ?? -1
            let message = error["message"] as? String ?? "Unknown app-server error"
            let normalized = message.lowercased()
            if normalized.contains("not signed") || normalized.contains("unauth") {
                throw AppServerError.unauthenticated
            }
            throw AppServerError.rpc(code: code, message: message)
        }

        guard let result = object["result"] as? [String: Any] else {
            throw AppServerError.invalidResponse
        }
        let snapshotObject: Any?
        if
            let buckets = result["rateLimitsByLimitId"] as? [String: Any],
            let codex = buckets["codex"]
        {
            snapshotObject = codex
        } else {
            snapshotObject = result["rateLimits"]
        }
        guard let snapshotObject else {
            throw AppServerError.invalidResponse
        }
        let snapshotData = try JSONSerialization.data(withJSONObject: snapshotObject)
        return try JSONDecoder().decode(RateLimitSnapshot.self, from: snapshotData)
    }
}

private final class LineQueue: @unchecked Sendable {
    private let condition = NSCondition()
    private var buffer = Data()
    private var lines: [String] = []
    private var isFinished = false

    func append(_ data: Data) {
        condition.lock()
        buffer.append(data)
        while let newline = buffer.firstIndex(of: 0x0A) {
            let lineData = buffer.prefix(upTo: newline)
            buffer.removeSubrange(...newline)
            if let line = String(data: lineData, encoding: .utf8) {
                lines.append(line)
            }
        }
        condition.broadcast()
        condition.unlock()
    }

    func finish() {
        condition.lock()
        isFinished = true
        condition.broadcast()
        condition.unlock()
    }

    func next(until deadline: Date) -> String? {
        condition.lock()
        defer { condition.unlock() }
        while lines.isEmpty && !isFinished {
            guard condition.wait(until: deadline) else { return nil }
        }
        guard !lines.isEmpty else { return nil }
        return lines.removeFirst()
    }
}
