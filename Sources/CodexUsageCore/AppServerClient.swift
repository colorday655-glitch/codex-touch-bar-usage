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

        let requests = [
            #"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"clientInfo":{"name":"codex-touch-bar","title":"Codex Touch Bar","version":"0.1.0"},"capabilities":{}}}"#,
            #"{"jsonrpc":"2.0","id":2,"method":"account/rateLimits/read","params":{}}"#,
        ].joined(separator: "\n") + "\n"

        inputPipe.fileHandleForWriting.write(Data(requests.utf8))
        try? inputPipe.fileHandleForWriting.close()

        let output = DataBox()
        let completed = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .userInitiated).async {
            output.set(outputPipe.fileHandleForReading.readDataToEndOfFile())
            completed.signal()
        }

        let waitResult = completed.wait(timeout: .now() + timeout)
        if waitResult == .timedOut {
            if process.isRunning {
                process.terminate()
            }
            try? outputPipe.fileHandleForReading.close()
            throw AppServerError.timeout
        }

        if process.isRunning {
            process.terminate()
        }
        guard let data = output.get(), !data.isEmpty else {
            throw AppServerError.disconnected
        }
        return try decodeRateLimits(from: data)
    }

    private func decodeRateLimits(from data: Data) throws -> RateLimitSnapshot {
        let lines = data.split(separator: 0x0A)
        for line in lines {
            guard
                let object = try JSONSerialization.jsonObject(with: Data(line)) as? [String: Any],
                (object["id"] as? NSNumber)?.intValue == 2
            else {
                continue
            }

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
        throw AppServerError.invalidResponse
    }
}

private final class DataBox: @unchecked Sendable {
    private let lock = NSLock()
    private var data: Data?

    func set(_ value: Data) {
        lock.lock()
        data = value
        lock.unlock()
    }

    func get() -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return data
    }
}
