# Codex Touch Bar Usage Display Design

## Goal

Display the remaining Codex rolling usage on the physical Touch Bar of a 2020
13-inch Intel MacBook Pro. The first line shows the five-hour window and the
second line shows the weekly window. The display is visible only while the
Codex desktop app is active or while Codex CLI is the foreground command in a
supported terminal.

## Constraints

- macOS public `NSTouchBar` APIs do not allow a helper app to inject controls
  into another foreground app's Touch Bar.
- The implementation therefore uses BetterTouchTool for Touch Bar ownership,
  visibility rules, and rendering.
- BetterTouchTool is not currently installed on the target Mac. Its preset
  import format must be validated against the installed version during
  implementation.
- Codex CLI 0.142.0-alpha.6 exposes the local app-server method
  `account/rateLimits/read`. Its generated protocol types include primary and
  secondary rate-limit windows with `usedPercent`, `windowDurationMins`, and
  `resetsAt` fields.

## Architecture

### Usage bridge

A small Swift command-line executable named `codex-usage` communicates with the
local Codex app-server over its standard-input/standard-output JSON-RPC
transport. It initializes the protocol, invokes `account/rateLimits/read`, and
selects the `codex` entry from `rateLimitsByLimitId`. If the multi-bucket entry
is absent, it falls back to the backward-compatible `rateLimits` snapshot.

The bridge never reads, copies, or logs `~/.codex/auth.json`. Authentication is
owned by the Codex app-server. Full server responses are not written to logs.

### Window mapping

The bridge identifies the five-hour and weekly windows primarily by
`windowDurationMins`, allowing small server-side duration variations. It uses
the snapshot's primary/secondary roles only as a compatibility fallback. It
calculates remaining usage as `100 - usedPercent` and clamps the result to the
inclusive range 0 through 100.

`resetsAt` is treated as a Unix timestamp and formatted relative to the local
clock. Five-hour resets use a compact duration such as `2时18分`; weekly resets
use a short local date or weekday such as `周一`.

### BetterTouchTool integration

BetterTouchTool owns one compact, two-line Touch Bar widget. The widget invokes
the bridge at a 60-second interval and renders its concise text output. The
preferred presentation is:

```text
5小时 ▰▰▰▰▱ 72%  2时18分
本周  ▰▰▱▱▱ 44%  周一
```

The five-hour line uses blue and the weekly line uses green where the installed
BetterTouchTool version supports per-line styling. Otherwise both use the
system high-contrast foreground color. The progress segments are textual so
the widget does not depend on unsupported custom `NSView` injection.

BetterTouchTool activation rules show the widget when:

1. The Codex desktop application is frontmost.
2. Terminal or iTerm is frontmost and its foreground TTY process is Codex CLI.

The widget produces no visible content in all other states. Terminal detection
must be based on the foreground process for the active terminal session, not a
global `pgrep`, so an unrelated background Codex process does not activate it.

## Refresh And Cache

Successful results are cached locally for fast widget rendering. A normal
refresh occurs every 60 seconds. If the app-server request fails, the bridge
may reuse the last successful value for at most five minutes and adds a middle
dot (`·`) to mark it stale. After cache expiry, it returns
`Codex 用量暂不可用`. An unauthenticated response returns
`请先在 Codex 登录`.

Cache data contains only percentages, window durations, reset timestamps, and
the last update time. It contains no credentials or account identifiers.

## Error Handling

- Missing individual windows render `--` without suppressing the other window.
- Missing or malformed percentages render `--` and are not cached as a valid
  update.
- Reset timestamps in the past render `即将重置` until a fresh snapshot is
  available.
- Protocol timeouts terminate the child app-server cleanly and fall back to the
  cache.
- Unexpected protocol fields are ignored for forward compatibility.
- Diagnostic output goes to standard error; widget output on standard output
  remains stable and concise.

## Testing

Unit and integration tests use a fake stdio app-server and a controllable clock.
Coverage includes:

- A normal five-hour and weekly response.
- The multi-bucket response and backward-compatible fallback response.
- Reordered primary and secondary data with duration-based identification.
- Missing windows, malformed fields, and values below 0 or above 100.
- Reset-time localization and past reset timestamps.
- Timeout, disconnect, unauthenticated response, fresh cache, and expired cache.
- Stable two-line output and error separation between stdout and stderr.
- Foreground-app and active-terminal-process detection.

Manual acceptance on the target Mac verifies:

- Both rows are legible on the physical Touch Bar.
- The display appears in Codex desktop and active Codex CLI sessions.
- The display disappears after switching to unrelated applications or terminal
  commands.
- Values update within 60 seconds of a rate-limit change.
- Offline and signed-out states match the specified fallback messages.

## Deliverables

- Swift source and automated tests for `codex-usage`.
- Reproducible build script.
- Idempotent install and uninstall scripts.
- A BetterTouchTool preset when supported by the installed version; otherwise,
  version-specific setup instructions with the exact activation conditions and
  widget command.
- A short README covering prerequisites, installation, troubleshooting, and
  privacy behavior.

## Out Of Scope

- Supporting Mac models without a physical Touch Bar.
- Modifying Codex.app or using private Apple Touch Bar frameworks.
- Displaying API billing, token counts, reset-credit balances, or limits other
  than the five-hour and weekly Codex windows.
- Supporting terminal applications other than Terminal and iTerm in the first
  release.

