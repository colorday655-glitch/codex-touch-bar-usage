# BetterTouchTool Setup

This directory contains the verified BetterTouchTool preset for Codex Touch Bar Usage.
The widget text follows the system language, with Chinese and English supported.

## Recommended Setup

Run the repository root setup script first:

```bash
scripts/setup.sh
```

That builds and installs the bridge, imports `CodexTouchBarUsage.bttpreset`, and refreshes the widget.
The preset refreshes every 15 seconds by default.

## Manual Setup

If you prefer to import the preset yourself:

1. Run `scripts/install.sh`.
2. Import `bettertouchtool/CodexTouchBarUsage.bttpreset` in BetterTouchTool.
3. Enable the imported **Codex Touch Bar Usage** preset.

Each widget runs:

```bash
"$HOME/Library/Application Support/CodexTouchBar/bin/codex-usage"
```

The widget is visible only when Codex is frontmost or when Codex CLI owns the active terminal session.

## Expected Output

Chinese system locale:

```text
5小时 🟩🟩🟩🟩⬜⬜⬜⬜⬜⬜ 39%  01:41        1周   🟩🟩🟩🟩🟩🟩⬜⬜⬜⬜ 55%  6月28日
```

English system locale:

```text
5h 🟩🟩🟩🟩⬜⬜⬜⬜⬜⬜ 39%  1:41 AM        1w   🟩🟩🟩🟩🟩🟩⬜⬜⬜⬜ 55%  Jun 28
```
