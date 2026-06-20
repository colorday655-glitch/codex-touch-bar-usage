# Codex Touch Bar Usage

Shows remaining Codex usage on a physical MacBook Pro Touch Bar:

```text
5小时 ▰▰▰▰▱ 81%  4时56分
本周 ▰▰▰▰▰ 97%  周日
```

The bridge reads Codex's local `account/rateLimits/read` app-server method. It
does not read, copy, or log `~/.codex/auth.json`.

## Requirements

- An Intel MacBook Pro with a physical Touch Bar.
- macOS 13 or newer.
- Codex.app installed and signed in.
- Swift 6.1 or newer to build from source.
- BetterTouchTool for displaying the result in another foreground app's Touch
  Bar context.

## Build And Test

```bash
swift test
scripts/build.sh
```

## Install

```bash
scripts/install.sh
```

The executable is installed at:

```text
~/Library/Application Support/CodexTouchBar/bin/codex-usage
```

Continue with [BetterTouchTool setup](bettertouchtool/README.md).

## Troubleshooting

- `请先在 Codex 登录`: open Codex.app and sign in.
- `Codex 用量暂不可用`: confirm Codex.app is installed at `/Applications`, then
  retry the forced command shown in the BetterTouchTool guide.
- A trailing `·`: the live request failed and a cache no older than five minutes
  is displayed.
- Nothing is printed: this is expected when Codex is not active. Use `--force`
  only for setup diagnostics.

Set `CODEX_EXECUTABLE` to an alternate Codex CLI path when Codex is not installed
at the standard application location.

## Privacy

The only persisted data is stored in
`~/Library/Caches/CodexTouchBar/usage.json`: percentages, window durations,
reset timestamps, and the last successful update time. No access tokens,
account identifiers, prompts, or conversation content are stored.

## Uninstall

```bash
scripts/uninstall.sh
```

This removes only the installed bridge and its cache. It does not remove or
modify BetterTouchTool.
