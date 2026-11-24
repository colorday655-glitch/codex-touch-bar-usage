# Gemini Touch Bar Usage Design

## Goal

When Antigravity is the active app, show its Gemini quota in the existing Touch Bar layout used by Codex: a five-hour window and a weekly window with green ten-segment bars, percentages, and the five-hour reset time.

## Data Source

Use Antigravity's read-only OAuth access token stored in the macOS Keychain item `service=gemini`, `account=antigravity`. Call the same internal Cloud Code endpoints used by Antigravity CLI:

1. `POST https://daily-cloudcode-pa.googleapis.com/v1internal:loadCodeAssist` with Antigravity metadata to resolve the account project.
2. `POST https://daily-cloudcode-pa.googleapis.com/v1internal:retrieveUserQuotaSummary` with that project to obtain model-group buckets.

The implementation must never write or refresh credentials. A failed fetch falls back to a Gemini-specific cache, so a transient network or quota error does not blank the widget.

## Architecture

- `GeminiUsageClient` conforms to the same `RateLimitFetching` protocol as `AppServerClient` and maps the Gemini model group buckets into `RateLimitSnapshot`.
- `UsageCache` gains a product-specific file URL so Codex and Gemini snapshots cannot overwrite each other.
- `ActivationDetector` recognizes `com.google.antigravity`; the executable routes Antigravity to `GeminiUsageClient` and Codex/terminal contexts to the existing client.
- `UsageFormatter` remains the shared renderer. Gemini snapshots omit reset-credit text because that field is not supplied by the Gemini quota API; the two window rows retain the current compact layout.

## Error Handling

- Missing keychain credential, expired token, permission denial, malformed response, HTTP errors, or timeout are treated as provider failures.
- A usable Gemini cache is rendered with the existing stale marker.
- If no usable cache exists, show the existing localized unavailable message.
- No secret, authorization header, or response body is written to logs or cache.

## Compatibility

Codex behavior and display remain unchanged. Antigravity is only active while `com.google.antigravity` is frontmost; terminal activation remains Codex-only.

## Acceptance

- Antigravity bundle ID is detected.
- A fixture Cloud Code response maps Gemini five-hour and weekly buckets to the shared snapshot model.
- Keychain token lookup is injectable/testable and does not write credentials.
- Codex and Gemini caches are separate.
- All existing tests pass, plus Gemini parsing, routing, cache fallback, and error tests.
