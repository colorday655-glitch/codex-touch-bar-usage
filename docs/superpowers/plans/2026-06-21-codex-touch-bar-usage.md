# Codex Touch Bar Usage Display Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an Intel-macOS command-line bridge that renders Codex five-hour and weekly remaining usage as a two-line BetterTouchTool widget.

**Architecture:** A Swift package isolates rate-limit decoding, window selection, formatting, caching, app-server JSON-RPC, and activation detection. The executable prints only widget text to stdout, while BetterTouchTool owns Touch Bar rendering and application visibility.

**Tech Stack:** Swift 6.1, Swift Package Manager, Foundation, Swift Testing, Codex app-server JSON-RPC, BetterTouchTool.

---

## File Map

- `Package.swift`: Swift package, library, executable, and test targets.
- `Sources/CodexUsageCore/RateLimits.swift`: protocol DTOs and duration-based window selection.
- `Sources/CodexUsageCore/UsageFormatter.swift`: remaining-percentage and two-line rendering.
- `Sources/CodexUsageCore/UsageCache.swift`: credential-free cache with a five-minute stale policy.
- `Sources/CodexUsageCore/AppServerClient.swift`: stdio JSON-RPC transport and rate-limit request.
- `Sources/CodexUsageCore/ActivationDetector.swift`: Codex app and foreground terminal process checks.
- `Sources/codex-usage/main.swift`: CLI orchestration and stable stdout/stderr contract.
- `Tests/CodexUsageCoreTests/*.swift`: deterministic unit and integration tests.
- `scripts/build.sh`: release build for the host architecture.
- `scripts/install.sh`: idempotent user-local installation.
- `scripts/uninstall.sh`: removal of installed project files.
- `bettertouchtool/README.md`: exact widget and activation-group setup.
- `README.md`: prerequisites, build, install, privacy, and troubleshooting.

### Task 1: Rate-limit Model And Two-line Formatter

**Files:**
- Create: `Package.swift`
- Create: `Sources/CodexUsageCore/RateLimits.swift`
- Create: `Sources/CodexUsageCore/UsageFormatter.swift`
- Create: `Tests/CodexUsageCoreTests/UsageFormatterTests.swift`

- [ ] **Step 1: Add failing selection and rendering tests**

Create tests that decode a `rateLimitsByLimitId.codex` snapshot, identify 300 and 10080 minute windows even when primary/secondary are reordered, clamp remaining percentages, and assert exactly two output lines:

```swift
@Test func rendersFiveHourAndWeeklyRows() throws {
    let snapshot = RateLimitSnapshot(
        primary: .init(usedPercent: 28, windowDurationMins: 300, resetsAt: 1_750_000_000),
        secondary: .init(usedPercent: 56, windowDurationMins: 10_080, resetsAt: 1_750_500_000)
    )
    let output = UsageFormatter(now: Date(timeIntervalSince1970: 1_749_991_720))
        .render(snapshot)
    #expect(output.split(separator: "\n").count == 2)
    #expect(output.contains("5小时"))
    #expect(output.contains("72%"))
    #expect(output.contains("本周"))
    #expect(output.contains("44%"))
}
```

- [ ] **Step 2: Run the focused test and verify failure**

Run: `swift test --filter UsageFormatterTests`

Expected: compilation fails because `RateLimitSnapshot` and `UsageFormatter` do not exist.

- [ ] **Step 3: Implement DTOs, selection, clamping, and rendering**

Use these public interfaces:

```swift
public struct RateLimitWindow: Codable, Equatable, Sendable {
    public let usedPercent: Double?
    public let windowDurationMins: Int?
    public let resetsAt: TimeInterval?
    public init(usedPercent: Double?, windowDurationMins: Int?, resetsAt: TimeInterval?)
}

public struct RateLimitSnapshot: Codable, Equatable, Sendable {
    public let primary: RateLimitWindow?
    public let secondary: RateLimitWindow?
    public init(primary: RateLimitWindow?, secondary: RateLimitWindow?)
    public func selectedWindows() -> (fiveHour: RateLimitWindow?, weekly: RateLimitWindow?)
}

public struct UsageFormatter: Sendable {
    public init(now: Date = Date())
    public func render(_ snapshot: RateLimitSnapshot, stale: Bool = false) -> String
}
```

Match durations within 60 minutes of 300 and within 24 hours of 10080. Render five text segments with `▰` and `▱`, `--` for a missing value, `即将重置` for past reset timestamps, and append ` ·` only to stale output.

- [ ] **Step 4: Run tests and verify pass**

Run: `swift test --filter UsageFormatterTests`

Expected: all formatter tests pass.

- [ ] **Step 5: Commit the model and formatter**

```bash
git add Package.swift Sources/CodexUsageCore/RateLimits.swift Sources/CodexUsageCore/UsageFormatter.swift Tests/CodexUsageCoreTests/UsageFormatterTests.swift
git commit -m "feat: format Codex rate limits for Touch Bar"
```

### Task 2: Credential-free Cache

**Files:**
- Create: `Sources/CodexUsageCore/UsageCache.swift`
- Create: `Tests/CodexUsageCoreTests/UsageCacheTests.swift`

- [ ] **Step 1: Add failing cache tests**

Cover a fresh cached snapshot, a stale-but-usable snapshot at 299 seconds, rejection at 301 seconds, malformed JSON, and confirm the encoded keys contain no token, account, or authentication fields.

```swift
@Test func expiresAfterFiveMinutes() throws {
    let stored = CachedUsage(snapshot: fixtureSnapshot, updatedAt: Date(timeIntervalSince1970: 1_000))
    #expect(stored.isUsable(at: Date(timeIntervalSince1970: 1_299)))
    #expect(!stored.isUsable(at: Date(timeIntervalSince1970: 1_301)))
}
```

- [ ] **Step 2: Run the test and verify failure**

Run: `swift test --filter UsageCacheTests`

Expected: compilation fails because `CachedUsage` does not exist.

- [ ] **Step 3: Implement atomic cache reads and writes**

```swift
public struct CachedUsage: Codable, Equatable, Sendable {
    public let snapshot: RateLimitSnapshot
    public let updatedAt: Date
    public func isUsable(at now: Date, maxAge: TimeInterval = 300) -> Bool
}

public struct UsageCache: Sendable {
    public let fileURL: URL
    public func load() throws -> CachedUsage?
    public func save(_ value: CachedUsage) throws
}
```

Write with `Data.write(options: .atomic)` under `~/Library/Caches/CodexTouchBar/usage.json`. Store only the two windows and update timestamp.

- [ ] **Step 4: Run cache and full tests**

Run: `swift test`

Expected: all tests pass.

- [ ] **Step 5: Commit the cache**

```bash
git add Sources/CodexUsageCore/UsageCache.swift Tests/CodexUsageCoreTests/UsageCacheTests.swift
git commit -m "feat: cache Touch Bar usage snapshots"
```

### Task 3: Codex App-server Client

**Files:**
- Create: `Sources/CodexUsageCore/AppServerClient.swift`
- Create: `Tests/CodexUsageCoreTests/AppServerClientTests.swift`
- Create: `Tests/Fixtures/fake-app-server.sh`

- [ ] **Step 1: Add failing JSON-RPC tests**

The fake server must accept newline-delimited JSON, reply to `initialize`, then reply to `account/rateLimits/read` with multi-bucket fixtures. Tests cover the `codex` bucket, compatible single snapshot, error response, disconnect, and timeout.

```swift
@Test func readsCodexBucket() async throws {
    let client = AppServerClient(executableURL: fakeServerURL, timeout: .seconds(2))
    let snapshot = try await client.fetchRateLimits()
    #expect(snapshot.primary?.windowDurationMins == 300)
    #expect(snapshot.secondary?.windowDurationMins == 10_080)
}
```

- [ ] **Step 2: Run test and verify failure**

Run: `swift test --filter AppServerClientTests`

Expected: compilation fails because `AppServerClient` does not exist.

- [ ] **Step 3: Implement process transport and JSON-RPC parsing**

```swift
public enum AppServerError: Error, Equatable {
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
    public init(executableURL: URL, timeout: Duration = .seconds(8))
    public func fetchRateLimits() async throws -> RateLimitSnapshot
}
```

Launch `<codex-path> app-server --stdio`, send JSON-RPC IDs 1 and 2 for `initialize` and `account/rateLimits/read`, select `rateLimitsByLimitId["codex"]` when present, and terminate the child on every exit path. Parse JSON with `JSONSerialization` at the envelope boundary and decode the selected payload with `JSONDecoder`.

- [ ] **Step 4: Run focused and full tests**

Run: `swift test --filter AppServerClientTests && swift test`

Expected: all tests pass and no fake app-server process remains.

- [ ] **Step 5: Commit the client**

```bash
git add Sources/CodexUsageCore/AppServerClient.swift Tests/CodexUsageCoreTests/AppServerClientTests.swift Tests/Fixtures/fake-app-server.sh
git commit -m "feat: read rate limits from Codex app server"
```

### Task 4: Activation Detection And CLI Orchestration

**Files:**
- Create: `Sources/CodexUsageCore/ActivationDetector.swift`
- Create: `Sources/codex-usage/main.swift`
- Create: `Tests/CodexUsageCoreTests/ActivationDetectorTests.swift`
- Create: `Tests/CodexUsageCoreTests/CLIPolicyTests.swift`

- [ ] **Step 1: Add failing activation and fallback-policy tests**

Inject frontmost bundle ID, active terminal TTY command, clock, client, and cache. Cover Codex desktop, active Terminal/iTerm Codex CLI, unrelated foreground command, successful fresh output, stale cache, expired cache, and unauthenticated output.

```swift
@Test func unrelatedTerminalCommandIsInactive() {
    let detector = ActivationDetector(
        frontmostBundleID: { "com.apple.Terminal" },
        foregroundTTYCommand: { "zsh" }
    )
    #expect(!detector.isCodexActive())
}
```

- [ ] **Step 2: Run tests and verify failure**

Run: `swift test --filter ActivationDetectorTests`

Expected: compilation fails because `ActivationDetector` does not exist.

- [ ] **Step 3: Implement activation and CLI policy**

```swift
public struct ActivationDetector: Sendable {
    public init(
        frontmostBundleID: @escaping @Sendable () -> String?,
        foregroundTTYCommand: @escaping @Sendable () -> String?
    )
    public func isCodexActive() -> Bool
}

public struct WidgetPolicy: Sendable {
    public func output(client: RateLimitFetching, cache: UsageCache, now: Date) async -> String
}
```

Recognize `com.openai.codex`, `com.apple.Terminal`, and `com.googlecode.iterm2`. For terminals, require the active TTY's foreground process name to equal `codex`, not merely contain it. The executable supports `--force` for testing/setup, prints an empty string when inactive, prints widget content to stdout, and sends diagnostics only to stderr.

- [ ] **Step 4: Run all tests and a forced smoke command**

Run: `swift test && swift run codex-usage --force`

Expected: tests pass; the smoke command prints two lines or one specified signed-out/unavailable message without a crash.

- [ ] **Step 5: Commit activation and CLI**

```bash
git add Sources/CodexUsageCore/ActivationDetector.swift Sources/codex-usage/main.swift Tests/CodexUsageCoreTests/ActivationDetectorTests.swift Tests/CodexUsageCoreTests/CLIPolicyTests.swift
git commit -m "feat: add context-aware Touch Bar usage command"
```

### Task 5: Build, Install, BetterTouchTool Setup, And Acceptance

**Files:**
- Create: `scripts/build.sh`
- Create: `scripts/install.sh`
- Create: `scripts/uninstall.sh`
- Create: `bettertouchtool/README.md`
- Create: `README.md`

- [ ] **Step 1: Add executable script checks**

Run scripts through `bash -n`; build into `.build/release`; install into `~/Library/Application Support/CodexTouchBar/bin`; verify uninstall removes only `CodexTouchBar` files. Scripts must use `set -euo pipefail`, quoted paths, and derive the repository root from their own location.

- [ ] **Step 2: Implement build and lifecycle scripts**

`build.sh` runs `swift build -c release`. `install.sh` copies `codex-usage` and prints the exact BetterTouchTool command. `uninstall.sh` removes the installed executable and cache, leaving BetterTouchTool itself untouched.

- [ ] **Step 3: Document BetterTouchTool configuration**

Document a 60-second Shell Script Widget using:

```bash
"$HOME/Library/Application Support/CodexTouchBar/bin/codex-usage"
```

Create activation groups for Codex, Terminal, and iTerm; the executable performs the final active-process guard. Record the preferred font size, two-line title, high-contrast colors, and how to verify the installed BTT version. Export a preset only after its schema is verified in the installed application.

- [ ] **Step 4: Run automated verification**

Run:

```bash
bash -n scripts/build.sh scripts/install.sh scripts/uninstall.sh
swift test
scripts/build.sh
git diff --check
```

Expected: syntax checks pass, all tests pass, release binary exists at `.build/release/codex-usage`, and `git diff --check` is silent.

- [ ] **Step 5: Run target-Mac acceptance checks**

After BetterTouchTool is installed, verify the two physical Touch Bar rows, Codex desktop visibility, active Terminal and iTerm Codex visibility, hiding for unrelated apps/commands, 60-second refresh, stale marker, signed-out message, and no credential data in the cache.

- [ ] **Step 6: Commit documentation and scripts**

```bash
git add scripts bettertouchtool README.md
git commit -m "docs: add Touch Bar installation workflow"
```
