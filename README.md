# Codex Touch Bar Usage

Open-source Touch Bar display for the Codex desktop app and Codex CLI on a MacBook Pro with a physical Touch Bar.

It shows the remaining Codex usage for the five-hour window and the weekly window, and only appears while Codex is active or while Codex CLI owns the foreground terminal session. The visible labels and reset timestamps follow the system language, with Chinese and English supported out of the box.

## Requirements

- MacBook Pro with a physical Touch Bar.
- macOS 13 or newer.
- Codex installed and signed in. The bridge will auto-detect the executable from `CODEX_EXECUTABLE`, `PATH`, `ChatGPT.app`, or `Codex.app`.
- BetterTouchTool installed at `/Applications/BetterTouchTool.app`.
- Swift 6.1 or newer if you want to build from source.

## Quick Start

Clone or download this repository, then run:

```bash
scripts/setup.sh
```

That script:

1. Builds the `codex-usage` bridge.
2. Installs it to `~/Library/Application Support/CodexTouchBar/bin/codex-usage`.
3. Imports the BetterTouchTool preset from `bettertouchtool/CodexTouchBarUsage.bttpreset`.
4. Refreshes the Touch Bar widget.

The BetterTouchTool preset refreshes every 15 seconds by default so the
Touch Bar stays close to the live Codex values.

After the script finishes, open BetterTouchTool and enable the imported preset named **Codex Touch Bar Usage**.

## Manual Install

If you prefer to do the steps yourself:

```bash
scripts/build.sh
scripts/install.sh
```

Then import `bettertouchtool/CodexTouchBarUsage.bttpreset` in BetterTouchTool and enable the preset.

The widget command is:

```bash
"$HOME/Library/Application Support/CodexTouchBar/bin/codex-usage"
```

## Expected Output

The widget renders a single line similar to:

Chinese system locale:

```text
5小时 🟩🟩🟩🟩⬜⬜⬜⬜⬜⬜ 39%  01:41        1周   🟩🟩🟩🟩🟩🟩⬜⬜⬜⬜ 55%  6月28日
```

English system locale:

```text
5h 🟩🟩🟩🟩⬜⬜⬜⬜⬜⬜ 39%  1:41 AM        1w   🟩🟩🟩🟩🟩🟩⬜⬜⬜⬜ 55%  Jun 28
```

The exact percentages and reset times come from the local Codex app-server.

## Verification

Run the bridge directly before configuring BetterTouchTool:

```bash
"$HOME/Library/Application Support/CodexTouchBar/bin/codex-usage" --force
```

If Codex is signed in, the command should print one line. If the widget is not visible yet, switch to Codex.app or to a terminal with Codex CLI running in the foreground and wait for the next refresh.

## Troubleshooting

- `请先在 Codex 登录` or `Sign in to Codex first`: open Codex and sign in.
- `Codex 用量暂不可用` or `Codex usage unavailable`: confirm Codex is installed or set `CODEX_EXECUTABLE` to the actual `codex` binary, then retry the forced command.
- A trailing `·`: the live request failed and a cache no older than five minutes is being shown.
- If the number still looks behind by a few seconds, wait for the next 15-second refresh cycle.
- Nothing is printed: this is expected when Codex is not active.
- If BetterTouchTool does not import the preset automatically, import `bettertouchtool/CodexTouchBarUsage.bttpreset` manually and enable **Codex Touch Bar Usage**.

## Uninstall

```bash
scripts/uninstall.sh
```

This removes the installed bridge and the cache under `~/Library/Application Support/CodexTouchBar` and `~/Library/Caches/CodexTouchBar`. It does not remove the BetterTouchTool preset.

## Privacy

The only persisted data is stored in `~/Library/Caches/CodexTouchBar/usage.json`: percentages, window durations, reset timestamps, and the last successful update time. No access tokens, account identifiers, prompts, or conversation content are stored.
