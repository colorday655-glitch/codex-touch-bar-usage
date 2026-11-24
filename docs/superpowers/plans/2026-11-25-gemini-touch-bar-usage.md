# Gemini Touch Bar Usage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Display Antigravity's Gemini five-hour and weekly quota in the existing Codex Touch Bar format.

**Architecture:** Add a `GeminiUsageClient` that conforms to `RateLimitFetching` and maps Antigravity's Cloud Code quota response into `RateLimitSnapshot`. Route by frontmost bundle ID, keep product-specific caches, and reuse the existing policy and formatter.

**Tech Stack:** Swift 6.1, Foundation, macOS Security/keychain command, URLSession, Swift Testing, BetterTouchTool shell widget.

**Spec:** `docs/superpowers/specs/2026-11-25-gemini-touch-bar-usage-design.md`

## Global Constraints

- Read the `gemini` / `antigravity` credential only; never write or refresh credentials.
- Use `daily-cloudcode-pa.googleapis.com/v1internal` with Antigravity metadata and User-Agent.
- Reuse `RateLimitSnapshot`, `RateLimitFetching`, `WidgetPolicy`, and `UsageFormatter` wherever possible.
- Keep Codex output and activation behavior unchanged.
- Do not persist tokens, authorization headers, or raw provider responses.

## Review Focus

- Keychain missing/expired token: return a safe provider failure and use cache.
- Cloud Code response with multiple model groups: select the Gemini group and its five-hour/weekly buckets.
- Malformed or partial buckets: preserve available windows without crashing.
- Antigravity frontmost routing: never invoke the Codex app-server for Antigravity.
- Separate caches: one provider failure must not display the other provider's quota.

### Task 1: Shared product-specific cache and rendering options

**Files:**
- Modify: `Sources/CodexUsageCore/UsageCache.swift`
- Modify: `Sources/CodexUsageCore/UsageFormatter.swift`
- Modify: `Sources/CodexUsageCore/WidgetPolicy.swift`
- Test: `Tests/CodexUsageCoreTests/UsageCacheTests.swift`
- Test: `Tests/CodexUsageCoreTests/UsageFormatterTests.swift`

**Interfaces:**
- `UsageCache.defaultFileURL(product:) -> URL` keeps Codex's existing path and adds a separate Gemini path.
- `UsageFormatter.render(_:stale:showResetCredits:) -> String` defaults to current Codex behavior and supports Gemini without a fabricated `0次可重置` prefix.

- [ ] Write failing tests for distinct Codex/Gemini cache URLs and Gemini rendering without reset-credit text.
- [ ] Run the focused tests and confirm failure.
- [ ] Implement the optional product-aware cache URL and formatter flag without changing default Codex output.
- [ ] Run focused tests and confirm they pass.
- [ ] Commit `refactor: separate provider caches and rendering options`.

### Task 2: Gemini quota client and response mapping

**Files:**
- Create: `Sources/CodexUsageCore/GeminiUsageClient.swift`
- Create: `Sources/CodexUsageCore/GeminiCredentialStore.swift`
- Test: `Tests/CodexUsageCoreTests/GeminiUsageClientTests.swift`
- Test fixture: `Tests/Fixtures/fake-gemini-quota-server.sh` or in-process URL protocol fixture

**Interfaces:**
- `GeminiUsageClient: RateLimitFetching` with injectable endpoint, credential store, URL session, and clock.
- `GeminiCredentialStore.readAccessToken() throws -> String` reads the Keychain item via a small injectable command boundary.

- [ ] Write failing parser/client tests for Gemini group selection, 5-hour/weekly bucket mapping, missing buckets, and HTTP failure.
- [ ] Run the focused tests and confirm failure.
- [ ] Implement read-only credential loading, `loadCodeAssist`, `retrieveUserQuotaSummary`, response parsing, and deadline handling.
- [ ] Run focused tests and confirm they pass without printing secrets.
- [ ] Commit `feat: read Antigravity Gemini quota`.

### Task 3: Antigravity activation and executable routing

**Files:**
- Modify: `Sources/CodexUsageCore/ActivationDetector.swift`
- Modify: `Sources/codex-usage/CodexUsageMain.swift`
- Test: `Tests/CodexUsageCoreTests/ActivationDetectorTests.swift`

**Interfaces:**
- Add `isAntigravityActive()` or an equivalent provider enum while preserving `isCodexActive()` behavior.
- Main selects `(client, cache, showResetCredits)` based on the frontmost app: Antigravity uses Gemini; Codex/terminal uses Codex.

- [ ] Write failing tests for `com.google.antigravity` activation and unchanged Codex/terminal routing.
- [ ] Run focused tests and confirm failure.
- [ ] Implement the route and call `WidgetPolicy.output` with the correct provider cache and rendering option.
- [ ] Run focused tests and confirm they pass.
- [ ] Commit `feat: route Antigravity Touch Bar usage`.

### Task 4: Documentation, release, and live verification

**Files:**
- Modify: `README.md`
- Modify: `bettertouchtool/CodexTouchBarUsage.bttpreset`
- Modify: `Sources/CodexUsageCore/Version.swift`

- [ ] Add Antigravity to supported apps and document the read-only Keychain requirement and failure fallback.
- [ ] Keep the existing widget command and add the Antigravity app trigger using the same executable.
- [ ] Run `swift test` and a release build.
- [ ] Install the release binary, import/refresh the BTT preset, and verify `--force` output using a live Antigravity quota response or a cached snapshot.
- [ ] Bump the patch version, commit, push, tag, and create the GitHub release.
