# BetterTouchTool Setup

## Prerequisite

BetterTouchTool 6.594 is installed at `/Applications/BetterTouchTool.app` on the
target Mac. Launch it once and grant the permissions requested by the
application. The project does not use private Apple Touch Bar frameworks;
BetterTouchTool owns the Touch Bar item.

## Import The Verified Preset

1. Run `scripts/install.sh` from this repository.
2. Import `bettertouchtool/CodexTouchBarUsage.bttpreset` in BetterTouchTool.
3. Enable the imported **Codex Touch Bar Usage** preset.

The preset was imported, restarted, and persistence-tested with BetterTouchTool
6.594. It contains application-specific Shell Script Widgets for Codex, Terminal,
and iTerm2. Each Widget runs:

```bash
"$HOME/Library/Application Support/CodexTouchBar/bin/codex-usage"
```

Periodic refresh is **60 seconds**, with multiline text, a compact font, black
background, and white text.

The command performs a second activation check. It emits no content unless the
frontmost app is Codex, or the active Terminal/iTerm TTY has `codex` as its
foreground process. This prevents an unrelated background Codex process from
showing the widget.

## Expected Output

```text
5小时 ▰▰▰▰▱ 81%  4时56分
本周 ▰▰▰▰▰ 97%  周日
```

The actual percentages and reset labels come from the local Codex app-server.
A trailing `·` means a cached value is being shown after a transient failure.

## Verification

Run the bridge directly before configuring the widget:

```bash
"$HOME/Library/Application Support/CodexTouchBar/bin/codex-usage" --force
```

It should print two rows. Then verify that the normal command is empty outside
Codex, appears while Codex is frontmost, appears while Codex CLI owns the active
terminal TTY, and disappears after the terminal returns to the shell.
