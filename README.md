# GPT & Gemini Touch Bar Usage

Open-source Touch Bar display for Codex and Google Antigravity on a MacBook Pro with a physical Touch Bar.

It shows the available earned reset credits and quota windows, and only appears while GPT/Codex or Antigravity is active. The visible labels and reset timestamps follow the system language, with Chinese and English supported out of the box.

## Requirements

- MacBook Pro with a physical Touch Bar.
- macOS 13 or newer.
- Codex installed and signed in. The bridge will auto-detect the executable from `CODEX_EXECUTABLE`, `PATH`, `ChatGPT.app`, or `Codex.app`.
- Antigravity installed and signed in if you want Gemini usage. The bridge reads the existing `gemini` / `antigravity` macOS Keychain credential without writing or refreshing it.
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

Only the latest GitHub release is expected to work. Older releases are self-disabled by the binary after checking GitHub.

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

Show the installed version with:

```bash
"$HOME/Library/Application Support/CodexTouchBar/bin/codex-usage" --version
```

## Expected Output

The widget renders a single line similar to:

Chinese system locale:

```text
2次可重置    5小时 🟩🟩🟩🟩🟩🟩🟩⬜⬜⬜ 72%  23:06    1周 🟩🟩🟩🟩⬜⬜⬜⬜⬜⬜ 44%
```

English system locale:

```text
2x reset    5h 🟩🟩🟩🟩🟩🟩🟩⬜⬜⬜ 72%  11:06 PM    1w 🟩🟩🟩🟩⬜⬜⬜⬜⬜⬜ 44%
```

The exact percentages and reset times come from the local Codex app-server.

When Antigravity is frontmost, the same widget switches to Gemini's Antigravity quota. Gemini has no earned reset-credit field, so its line starts directly with `5小时` / `5h` and the two quota windows.

## Verification

Run the bridge directly before configuring BetterTouchTool:

```bash
"$HOME/Library/Application Support/CodexTouchBar/bin/codex-usage" --force
```

If Codex or Antigravity is signed in, the command should print one line. If the widget is not visible yet, switch to ChatGPT.app, Antigravity, or a terminal with Codex CLI running in the foreground and wait for the next refresh.

## Troubleshooting

- `请先在 GPT 登录` or `Sign in to GPT first`: open the GPT/Codex app and sign in.
- `GPT 用量暂不可用` or `GPT usage unavailable`: confirm Codex is installed or set `CODEX_EXECUTABLE` to the actual `codex` binary, then retry the forced command.
- `GPT 用量暂不可用` while Antigravity is frontmost: confirm Antigravity is signed in and that the `gemini` / `antigravity` Keychain item is available; the Gemini quota endpoint is internal to Antigravity and may be unavailable during a Google service issue.
- A trailing `·`: the live request failed and a cache no older than five minutes is being shown.
- If the number still looks behind by a few seconds, wait for the next 15-second refresh cycle.
- Nothing is printed: this is expected when Codex is not active.
- `This release is outdated. Install the latest GitHub release.`: update to the newest GitHub release; older releases intentionally stop working.
- If BetterTouchTool does not import the preset automatically, import `bettertouchtool/CodexTouchBarUsage.bttpreset` manually and enable **Codex Touch Bar Usage**.

## Uninstall

```bash
scripts/uninstall.sh
```

This removes the installed bridge and the cache under `~/Library/Application Support/CodexTouchBar` and `~/Library/Caches/CodexTouchBar`. It does not remove the BetterTouchTool preset.

## Privacy

The only persisted data is stored in `~/Library/Caches/CodexTouchBar/usage.json` and `gemini-usage.json`: percentages, window durations, reset timestamps, and the last successful update time. The Antigravity access token is read in memory from Keychain and never stored, refreshed, or logged. No account identifiers, prompts, or conversation content are stored.
